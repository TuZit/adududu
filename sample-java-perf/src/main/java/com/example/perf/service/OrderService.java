package com.example.perf.service;

import com.example.perf.domain.Order;
import com.example.perf.domain.OrderItem;
import com.example.perf.repository.OrderRepository;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.regex.Pattern;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {

    private final OrderRepository orderRepository;

    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    // PERF-SPRING-001 (N+1) + PERF-SPRING-004 (batch fetch) + PERF-SPRING-012 (repository/association access in loop)
    @Transactional(readOnly = true)
    public List<String> listOrderSummariesWithNPlusOne() {
        List<Order> orders = orderRepository.findAll();
        List<String> result = new ArrayList<>();
        for (Order order : orders) {
            // lazy association access -> one extra SELECT per order
            String customerName = order.getCustomer().getName();
            for (OrderItem item : order.getItems()) {          // another SELECT per order
                result.add(customerName + ":" + item.getSku());
            }
        }
        return result;
    }

    // PERF-SPRING-007 (unbounded retrieval) + PERF-JAVA-003 (String concat in loop)
    @Transactional(readOnly = true)
    public int countAllOrders() {
        List<Order> orders = orderRepository.findAll(); // loads the whole table into memory
        String out = "";
        for (Order o : orders) {
            out = out + o.getId() + ",";               // PERF-JAVA-003
        }
        return out.length();
    }

    // PERF-SPRING-005 (bulk write, save in loop) + PERF-JAVA-015 (repeated DB statement prep)
    @Transactional
    public void createOrdersBulk(List<Order> orders) {
        for (Order order : orders) {
            orderRepository.save(order);               // one INSERT per iteration, no batching
        }
    }

    // PERF-SPRING-008 (Page runs a COUNT) + PERF-SPRING-009 (large offset)
    @Transactional(readOnly = true)
    public List<Order> pageOrdersWithLargeOffset(int page) {
        return orderRepository.findAll(PageRequest.of(page, 50)).getContent();
    }

    // PERF-JAVA-009 (heavy object recreated on a repeated path)
    public List<String> formatDates(List<Date> dates) {
        List<String> out = new ArrayList<>();
        for (Date d : dates) {
            SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd"); // recreated each iteration
            out.add(fmt.format(d));
        }
        return out;
    }

    // PERF-JAVA-014 (Pattern.compile repeated in loop)
    public boolean anyMatch(List<String> inputs, String regex) {
        for (String s : inputs) {
            if (Pattern.compile(regex).matcher(s).matches()) {       // compiled per iteration
                return true;
            }
        }
        return false;
    }

    // PERF-JAVA-001 (allocation in loop) + PERF-JAVA-008 (wrapper construction) + PERF-JAVA-012 (System.gc)
    public long allocateInLoop(int n) {
        long sum = 0;
        for (int i = 0; i < n; i++) {
            List<Object> tmp = new ArrayList<>();       // PERF-JAVA-001
            tmp.add(new Integer(i));                    // PERF-JAVA-008
            sum += tmp.size();
        }
        System.gc();                                    // PERF-JAVA-012
        return sum;
    }

    // PERF-JAVA-002 (manual array copy where System.arraycopy applies)
    public int[] copyArray(int[] src) {
        int[] dst = new int[src.length];
        for (int i = 0; i < src.length; i++) {
            dst[i] = src[i];                            // manual copy
        }
        return dst;
    }
}
