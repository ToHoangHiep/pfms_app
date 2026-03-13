package com.pfms.api.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MeController {

    @GetMapping("/api/me")
    public String me(HttpServletRequest request) {
        Object uid = request.getAttribute("uid");
        return "uid=" + uid;
    }
}