package com.instagram.server.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.converter.DefaultContentTypeResolver;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.converter.MessageConverter;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.util.MimeTypeUtils;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;
import java.util.TimeZone;

@Configuration
@EnableWebSocketMessageBroker
@SuppressWarnings("unused")

/* WebSocketMessageBrokerConfigurer
* Defines methods for configuring message handling with simple messaging protocols (for example, STOMP)
* from WebSocket clients.*/
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    /*
    * Creates WebSocket URLs that clients can connect to
    * Sets up the initial handshake between client and server
    */
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        /*Creates a WebSocket endpoint at URL: ws://localhost:8080/ws*/
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .setAllowedOrigins("*")
                /*Note: In the future can remove sockjs*/
                .withSockJS()
                .setClientLibraryUrl("https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js");
        
        // Also add a plain WebSocket endpoint for testing
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .setAllowedOrigins("*");
    }

    /*like postal-system for a real-time message,
    * configure how messages are routed and delivered in your WebSocket application*/
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        /*Client sends messages to destinations starting with /app
        Server handles these messages with @MessageMapping annotations*/
        registry.setApplicationDestinationPrefixes("/app");
        
        // Defines where the server sends messages TO clients
        //  subscribe to these destinations to receive messages
        registry.enableSimpleBroker("/user", "/topic", "/queue", "/notifications");
        
        // Enable user destination prefixes
        registry.setUserDestinationPrefix("/user");
    }
    
    @Override
    public boolean configureMessageConverters(List<MessageConverter> messageConverters) {
        DefaultContentTypeResolver resolver = new DefaultContentTypeResolver();
        resolver.setDefaultMimeType(MimeTypeUtils.APPLICATION_JSON);
        
        MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
        converter.setObjectMapper(createObjectMapper());
        converter.setContentTypeResolver(resolver);
        
        messageConverters.add(converter);
        return false;
    }
    
    @Bean
    public ObjectMapper createObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
        mapper.setTimeZone(TimeZone.getTimeZone("UTC"));
        return mapper;
    }
} 