package com.instagram.server.controller;

import com.instagram.server.dto.request.UserRequest;
import com.instagram.server.dto.response.AuthenticationResponse;
import com.instagram.server.service.AuthenticationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthenticationController {

    private final AuthenticationService authenticationService;

    public AuthenticationController(AuthenticationService authenticationService) {
        this.authenticationService = authenticationService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> register(@RequestBody UserRequest request){
        return ResponseEntity.ok(authenticationService.register(request));
    }

    @PostMapping("/login")
    private ResponseEntity<AuthenticationResponse> login(@RequestBody UserRequest request){
        return ResponseEntity.ok(authenticationService.authenticted(request));
    }
}
