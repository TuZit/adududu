package com.example.perf.util;

import java.util.Vector;

public class JavaPerfSmells {

    // PERF-JAVA-003: String concatenation in a loop
    public String joinNames(String[] names) {
        String result = "";
        for (String n : names) {
            result += n;
        }
        return result;
    }

    // PERF-JAVA-004: inefficient empty/blank check creating a temporary value
    public boolean isBlank(String s) {
        return s.trim().length() == 0;
    }

    // PERF-JAVA-005: redundant String conversion
    public String redundantToString(String s) {
        return s.toString();
    }

    // PERF-JAVA-006 / PERF-JAVA-007: avoidable String append
    public String buildLabel(String a, String b) {
        StringBuilder sb = new StringBuilder();
        sb.append(a + b);
        return sb.toString();
    }

    // PERF-JAVA-010: inefficient collection implementation choice
    public void useVector() {
        Vector<Integer> v = new Vector<>();
        for (int i = 0; i < 1000; i++) {
            v.add(i);
        }
    }

    // PERF-JAVA-013: blocking/expensive operation in a loop
    public void sleepInLoop(int n) throws InterruptedException {
        for (int i = 0; i < n; i++) {
            Thread.sleep(50);
        }
    }
}
