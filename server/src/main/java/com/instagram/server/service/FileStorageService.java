package com.instagram.server.service;

import java.io.IOException;

public interface FileStorageService {
    String storeImage(String imageData, String directory) throws IOException;
    void deleteFile(String filePath) throws IOException;
}
