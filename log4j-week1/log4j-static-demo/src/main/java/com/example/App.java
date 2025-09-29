package com.example;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class App {
    private static final Logger log = LogManager.getLogger(App.class);

    public static void main(String[] args) {
        log.info("Hello from STATIC Log4j app!");
        log.warn("This is a warning message from static Log4j");
        log.error("This is an error message from static Log4j");
        System.out.println("Static app: logger call completed.");
    }
}
