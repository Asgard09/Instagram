package com.instagram.server.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.UUID;

@Service
public class FileStorageService {

    @Value("${app.file.upload-dir:uploads}")
    private String uploadDir;

    /**
     * Stores an image in a folder and returns the file path.
     * Can handle both base64 encoded images and URL strings
     */
    public String storeImage(String imageData, String directory) throws IOException {
        // Create directory if it doesn't exist
        Path dirPath = Paths.get(uploadDir, directory);
        Files.createDirectories(dirPath);

        // Generate a unique filename
        String filename = UUID.randomUUID().toString() + ".jpg";
        Path filePath = Paths.get(dirPath.toString(), filename);

        // Check if it's a base64 image or a URL/blob reference
        if (imageData.startsWith("data:image")) {
            // It's a base64 image with prefix
            String base64Data = imageData.split(",")[1];
            byte[] imageBytes = Base64.getDecoder().decode(base64Data);
            try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
                fos.write(imageBytes);
            }
        } else if (imageData.startsWith("blob:") || imageData.startsWith("http")) {
            // For now, with blob or http URLs, we just store a placeholder
            // In a real app, you would download the image using HttpClient or similar
            // For this demo, we'll create a small placeholder file
            String placeholderText = "Image URL: " + imageData;
            Files.write(filePath, placeholderText.getBytes());
        } else {
            // Assume it's a plain base64 string without prefix
            try {
                byte[] imageBytes = Base64.getDecoder().decode(imageData);
                try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
                    fos.write(imageBytes);
                }
            } catch (IllegalArgumentException e) {
                // If decoding fails, treat it as plain text
                String placeholderText = "Image data: " + imageData;
                Files.write(filePath, placeholderText.getBytes());
            }
        }

        // Return the relative path to access the image
        return directory + "/" + filename;
    }

    public void deleteFile(String filePath) throws IOException {
        Path path = Paths.get(uploadDir, filePath);
        Files.deleteIfExists(path);
    }
} 