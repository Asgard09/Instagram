package com.instagram.server.service.Impl;

import com.instagram.server.base.ImageType;
import com.instagram.server.service.FileStorageService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.HttpURLConnection;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.UUID;

@Service
@SuppressWarnings("unused")
public class FileStorageServiceImpl implements FileStorageService {

    @Value("${app.file.upload-dir:uploads}")
    private String uploadDir;

    /**
     * Stores an image in a folder and returns the file path.
     * Can handle both base64 encoded images and URL strings
     */
    public String storeImage(String imageData, String directory) throws IOException {
        // Check for empty or null data
        if (isInvalidImageData(imageData)) return null;
        
        // Create directory if it doesn't exist
        createDirectoryIfNotExists(directory);
        ImageType type = detectImageType(imageData);

        return switch (type){
            case DATA_URL -> handleDataUrl(imageData, directory);
            case HTTP_URL -> handleHttpUrl(imageData, directory);
            case BLOB_URL -> handleBlobUrl(imageData, directory);
            case BASE64 -> handleBase64(imageData, directory);
            case INVALID -> null;
        };
    }

    private boolean isInvalidImageData(String imageData){
        return imageData == null || imageData.trim().isEmpty();
    }

    private void createDirectoryIfNotExists(String directory) throws IOException{
        Path dirPath = Paths.get(uploadDir, directory);
        Files.createDirectories(dirPath);
    }

    private ImageType detectImageType(String imageData) {
        String trimmed = imageData.trim();

        if (trimmed.startsWith("data:image/")) return ImageType.DATA_URL;
        if (trimmed.startsWith("http")) return ImageType.HTTP_URL;
        if (trimmed.startsWith("blob:")) return ImageType.BLOB_URL;
        if (isValidBase64(trimmed)) return ImageType.BASE64;

        return ImageType.INVALID;
    }

    private boolean isValidBase64(String data) {
        try {
            // Remove whitespace and check if it's valid base64
            String cleaned = data.replaceAll("\\s", "");
            Base64.getDecoder().decode(cleaned);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private String handleDataUrl(String imageData, String directory) throws IOException {
        int commaIndex = imageData.indexOf(",");
        if (commaIndex == -1) {
            return null;
        }

        String mimeInfo = imageData.substring(0, commaIndex);
        String base64Data = imageData.substring(commaIndex + 1);
        String extension = extractExtensionFromMimeInfo(mimeInfo);

        return saveBase64ToFile(base64Data, directory, extension);
    }

    private String handleHttpUrl(String imageData, String directory){
        try {
            URL url = new URL(imageData);
            HttpURLConnection connection = createConnection(url);

            if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                return null;
            }

            String extension = getExtensionFromContentType(connection.getContentType());
            String filename = generateFilename(extension);
            Path filePath = getFilePath(directory, filename);

            downloadFile(connection, filePath);
            return directory + "/" + filename;

        } catch (Exception e) {
            throw new RuntimeException("Failed to download from URL: " + imageData + ", Error: " + e.getMessage());
        }
    }

    private String handleBlobUrl(String imageData, String directory){
        return "Received blob URL that can't be processed: " + imageData;
    }

    private String handleBase64(String imageData, String directory) throws IOException {
        return saveBase64ToFile(imageData, directory, ".jpg");
    }

    private HttpURLConnection createConnection(URL url) throws IOException {
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod("GET");
        connection.setConnectTimeout(5000);
        connection.setReadTimeout(5000);
        return connection;
    }

    private void downloadFile(HttpURLConnection connection, Path filePath) throws IOException {
        try (InputStream in = connection.getInputStream();
             FileOutputStream out = new FileOutputStream(filePath.toFile())) {

            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }

    private String saveBase64ToFile(String base64Data, String directory, String extension) throws IOException {
        try {
            String cleanedData = base64Data.replaceAll("\\s", "");
            byte[] imageBytes = Base64.getDecoder().decode(cleanedData);

            String filename = generateFilename(extension);
            Path filePath = getFilePath(directory, filename);

            try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
                fos.write(imageBytes);
            }

            return directory + "/" + filename;

        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Save failed " + e.getMessage());
        }
    }

    private String extractExtensionFromMimeInfo(String mimeInfo) {
        if (mimeInfo.contains("image/png")) return ".png";
        if (mimeInfo.contains("image/gif")) return ".gif";
        if (mimeInfo.contains("image/webp")) return ".webp";
        return ".jpg";
    }

    private String generateFilename(String extension) {
        return UUID.randomUUID() + extension;
    }

    private Path getFilePath(String directory, String filename) {
        return Paths.get(uploadDir, directory, filename);
    }

    public void deleteFile(String filePath) throws IOException {
        Path path = Paths.get(uploadDir, filePath);
        Files.deleteIfExists(path);
    }

    private String getExtensionFromContentType(String contentType) {
        if (contentType.contains("image/png")) {
            return ".png";
        } else if (contentType.contains("image/gif")) {
            return ".gif";
        } else if (contentType.contains("image/webp")) {
            return ".webp";
        } else if (contentType.contains("image/jpg") || contentType.contains("image/jpeg")) {
            return ".jpg";
        }
        return ".jpg"; // Default fallback
    }

} 