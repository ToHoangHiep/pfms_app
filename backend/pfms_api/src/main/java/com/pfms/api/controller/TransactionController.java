package com.pfms.api.controller;

import com.pfms.api.dto.TransactionDto;
import com.pfms.api.service.TransactionService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
public class TransactionController {

    private final TransactionService service;

    public TransactionController(TransactionService service) {
        this.service = service;
    }

    private String uid(HttpServletRequest request) {
        return String.valueOf(request.getAttribute("uid"));
    }

    @PostMapping(value = "/api/transactions", produces = "application/json; charset=UTF-8")
    public Map<String, Object> create(@RequestBody TransactionDto dto,
                                      HttpServletRequest request) throws ExecutionException, InterruptedException {
        String id = service.create(uid(request), dto);
        return Map.of("id", id);
    }

    @GetMapping(value = "/api/transactions", produces = "application/json; charset=UTF-8")
    public List<TransactionDto> list(HttpServletRequest request) throws ExecutionException, InterruptedException {
        return service.list(uid(request));
    }

    @GetMapping(value = "/api/transactions/{id}", produces = "application/json; charset=UTF-8")
    public TransactionDto getById(@PathVariable String id, HttpServletRequest request)
            throws ExecutionException, InterruptedException {

        return service.getById(uid(request), id);
    }

    @PutMapping(value = "/api/transactions/{id}", produces = "application/json; charset=UTF-8")
    public Map<String, Object> update(@PathVariable String id,
                                      @RequestBody TransactionDto dto,
                                      HttpServletRequest request)
            throws ExecutionException, InterruptedException {

        service.update(uid(request), id, dto);
        return Map.of("updated", true);
    }

    @DeleteMapping(value = "/api/transactions/{id}", produces = "application/json; charset=UTF-8")
    public Map<String, Object> delete(@PathVariable String id,
                                      HttpServletRequest request) throws ExecutionException, InterruptedException {
        service.delete(uid(request), id);
        return Map.of("deleted", true);
    }
}