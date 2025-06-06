package com.instagram.server.config;

import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
@SuppressWarnings("unused")
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.file.upload-dir:uploads}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(@NotNull ResourceHandlerRegistry registry) {
        // Convert to an absolute path and ensure it ends with a slash
        Path uploadsPath = Paths.get(uploadDir).toAbsolutePath();
        String uploadsDirPath = uploadsPath.toString().replace('\\', '/');
        if (!uploadsDirPath.endsWith("/")) {
            uploadsDirPath += "/";
        }
        
        System.out.println("Configuring resource handler for uploads at: " + uploadsDirPath);
        
        // Register resource handler for images with explicit file:/ protocol
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:/" + uploadsDirPath)
                .setCachePeriod(0); // Disable caching during development
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }
} 