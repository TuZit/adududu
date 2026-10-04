package com.example.perf.repository;

import com.example.perf.domain.Order;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {

    // PERF-SPRING-007 / PERF-SPRING-013: unbounded derived query returning a full List.
    List<Order> findByCustomerId(Long customerId);
}
