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

    //Stores a Base64-encoded image in a folder and returns the file path.
    public String storeBase64Image(String base64Image, String directory) throws IOException {
        // Create directory if it doesn't exist
        Path dirPath = Paths.get(uploadDir, directory);
        Files.createDirectories(dirPath);

        // Generate a unique filename
        String filename = UUID.randomUUID().toString() + ".jpg";
        Path filePath = Paths.get(dirPath.toString(), filename);

        // Remove base64 prefix if present (e.g., "data:image/jpeg;base64,")
        String base64Data = base64Image;
        if (base64Data.contains(",")) {
            base64Data = base64Data.split(",")[1];
        }

        // Decode and save the image
        byte[] imageBytes = Base64.getDecoder().decode(base64Data);
        try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
            fos.write(imageBytes);
        }

        // Return the relative path to access the image
        return directory + "/" + filename;
    }

    public void deleteFile(String filePath) throws IOException {
        Path path = Paths.get(uploadDir, filePath);
        Files.deleteIfExists(path);
    }
} 