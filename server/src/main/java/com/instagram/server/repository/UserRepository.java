package com.instagram.server.repository;

import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    /*contains a string (case-insensitive)*/
    List<User> findByUsernameContainingIgnoreCaseOrNameContainingIgnoreCase(String username, String name);
}
