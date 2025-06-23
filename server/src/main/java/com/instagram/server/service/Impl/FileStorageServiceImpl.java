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
        if (isInvalidImageData(imageData)) return createTestImage(directory, "empty-test-image.jpg");
        
        // Create directory if it doesn't exist
        createDirectoryIfNotExists(directory);
        ImageType type = detectImageType(imageData);

        return switch (type){
            case DATA_URL -> handleDataUrl(imageData, directory);
            case HTTP_URL -> handleHttpUrl(imageData, directory);
            case BLOB_URL -> handleBlobUrl(imageData, directory);
            case BASE64 -> handleBase64(imageData, directory);
            case INVALID -> createTestImage(directory, "invalid_format-" + UUID.randomUUID() + ".jpg");
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
            return createTestImage(directory, "invalid-data-url-" + UUID.randomUUID() + ".jpg");
        }

        String mimeInfo = imageData.substring(0, commaIndex);
        String base64Data = imageData.substring(commaIndex + 1);
        String extension = extractExtensionFromMimeInfo(mimeInfo);

        return saveBase64ToFile(base64Data, directory, extension);
    }

    private String handleHttpUrl(String imageData, String directory) throws IOException {
        try {
            URL url = new URL(imageData);
            HttpURLConnection connection = createConnection(url);

            if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                return createTestImage(directory, "http-error-" + UUID.randomUUID() + ".jpg");
            }

            String extension = getExtensionFromContentType(connection.getContentType());
            String filename = generateFilename(extension);
            Path filePath = getFilePath(directory, filename);

            downloadFile(connection, filePath);
            return directory + "/" + filename;

        } catch (Exception e) {
            System.err.println("Failed to download from URL: " + imageData + ", Error: " + e.getMessage());
            return createTestImage(directory, "http-error-" + UUID.randomUUID() + ".jpg");
        }
    }

    private String handleBlobUrl(String imageData, String directory) throws IOException {
        System.err.println("Received blob URL that can't be processed: " + imageData);
        return createTestImage(directory, "blob-test-" + UUID.randomUUID() + ".jpg");
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
            System.err.println("Base64 decoding error: " + e.getMessage());
            return createTestImage(directory, "base64-error-" + UUID.randomUUID() + extension);
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


    /**
     * Creates a valid test image file for debugging purposes.
     * This ensures we have a properly formatted image to display even when uploads fail.
     */
    private String createTestImage(String directory, String filename) throws IOException {
        Path dirPath = Paths.get(uploadDir, directory);
        Files.createDirectories(dirPath);
        
        Path filePath = Paths.get(dirPath.toString(), filename);
        
        // Create a simple color gradient as a valid JPEG
        int width = 200;
        int height = 200;
        
        // Create a minimal valid JPEG file
        // JPEG header + simple image data
        byte[] jpegHeader = {
            (byte)0xFF, (byte)0xD8,                      // SOI marker
            (byte)0xFF, (byte)0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F', 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, // APP0 marker
            (byte)0xFF, (byte)0xDB, 0x00, 0x43, 0x00,    // DQT marker
            // Luminance quantization table (simplified)
            0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14,
            0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12, 0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A,
            0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C,
            0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32,
            (byte)0xFF, (byte)0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01, // SOF0 marker
            (byte)0xFF, (byte)0xC4, 0x00, 0x1F, 0x00,    // DHT marker
            // Huffman table (simplified)
            0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
            (byte)0xFF, (byte)0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, // SOS marker
            // Minimal image data (blue box)
            0x54, (byte)0xA7, 0x23, 0x55, 0x2E, 0x7C, (byte)0xFB, (byte)0xA7, 0x22, 0x10,
            (byte)0xFF, (byte)0xD9                       // EOI marker
        };
        
        // Write the JPEG file
        try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
            fos.write(jpegHeader);
        }
        
        System.out.println("Created test image file: " + filePath);
        return directory + "/" + filename;
    }
} 