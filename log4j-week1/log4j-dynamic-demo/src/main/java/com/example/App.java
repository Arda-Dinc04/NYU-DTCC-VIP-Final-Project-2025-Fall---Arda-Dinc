package com.example;

import java.io.File;
import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;

public class App {
    public static void main(String[] args) throws Exception {
        // Look for JARs under runtime-libs/
        File libs = new File("runtime-libs");
        if (!libs.exists() || !libs.isDirectory()) {
            System.out.println("runtime-libs/ not found — please put log4j-api and log4j-core jars there.");
            System.out.println("Download log4j-api-2.25.2.jar and log4j-core-2.25.2.jar from:");
            System.out.println("https://logging.apache.org/log4j/2.x/download.html");
            return;
        }

        File apiJar = new File(libs, "log4j-api-2.25.2.jar");
        File coreJar = new File(libs, "log4j-core-2.25.2.jar");
        if (!apiJar.exists() || !coreJar.exists()) {
            System.out.println("Missing expected jars: " + apiJar.getName() + " or " + coreJar.getName());
            System.out.println("Download and place them in runtime-libs/");
            return;
        }

        URL[] urls = new URL[] { apiJar.toURI().toURL(), coreJar.toURI().toURL() };
        try (URLClassLoader cl = new URLClassLoader(urls, App.class.getClassLoader())) {
            // Load LogManager and Logger via reflection
            Class<?> logManager = Class.forName("org.apache.logging.log4j.LogManager", true, cl);
            Method getLogger = logManager.getMethod("getLogger", Class.class);
            Object logger = getLogger.invoke(null, App.class);

            Class<?> loggerInterface = Class.forName("org.apache.logging.log4j.Logger", true, cl);
            Method info = loggerInterface.getMethod("info", Object.class);
            Method warn = loggerInterface.getMethod("warn", Object.class);
            Method error = loggerInterface.getMethod("error", Object.class);

            info.invoke(logger, "Hello from DYNAMIC Log4j app!");
            warn.invoke(logger, "This is a warning message from dynamic Log4j");
            error.invoke(logger, "This is an error message from dynamic Log4j");

            System.out.println("Dynamic app: logger invocation done.");
        }
    }
}
