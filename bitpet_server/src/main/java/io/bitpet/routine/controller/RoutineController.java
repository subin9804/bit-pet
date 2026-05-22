package io.bitpet.routine.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.routine.dto.RoutineCompleteBatchRequest;
import io.bitpet.routine.dto.RoutineCompleteIndividualRequest;
import io.bitpet.routine.dto.RoutineCreateRequest;
import io.bitpet.routine.dto.RoutineLogResponse;
import io.bitpet.routine.dto.RoutineResponse;
import io.bitpet.routine.dto.TodayRoutineResponse;
import io.bitpet.routine.dto.RoutineUpdateRequest;
import io.bitpet.routine.service.RoutineService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1")
public class RoutineController {

    private final RoutineService routineService;

    // -------------------------------------------------------------------------
    // Routine CRUD (user-owned)
    // -------------------------------------------------------------------------

    @GetMapping("/routines")
    public ApiResponse<List<RoutineResponse>> listRoutines(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(routineService.listRoutines(principal.userId()));
    }

    @GetMapping("/routines/{routineId}")
    public ApiResponse<RoutineResponse> getRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.getRoutine(principal.userId(), routineId));
    }

    @PostMapping("/routines")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<RoutineResponse> createRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody RoutineCreateRequest req) {
        return ApiResponse.ok(routineService.createRoutine(principal.userId(), req));
    }

    @PutMapping("/routines/{routineId}")
    public ApiResponse<RoutineResponse> updateRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @Valid @RequestBody RoutineUpdateRequest req) {
        return ApiResponse.ok(routineService.updateRoutine(principal.userId(), routineId, req));
    }

    @DeleteMapping("/routines/{routineId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId) {
        routineService.deleteRoutine(principal.userId(), routineId);
    }

    // -------------------------------------------------------------------------
    // Today's routines
    // -------------------------------------------------------------------------

    @GetMapping("/routines/today")
    public ApiResponse<List<TodayRoutineResponse>> listTodayRoutines(
            @AuthenticationPrincipal AuthPrincipal principal) {
        return ApiResponse.ok(routineService.listTodayRoutines(principal.userId()));
    }

    @GetMapping("/routines/{routineId}/today")
    public ApiResponse<TodayRoutineResponse> getTodayRoutineStatus(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.getTodayRoutineStatus(principal.userId(), routineId));
    }

    // -------------------------------------------------------------------------
    // Pet subscription
    // -------------------------------------------------------------------------

    @GetMapping("/routines/{routineId}/pets")
    public ApiResponse<List<Long>> listRoutinePets(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.listSubscribedPets(principal.userId(), routineId));
    }

    @PostMapping("/routines/{routineId}/pets/{petId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void subscribePet(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @PathVariable Long petId) {
        routineService.subscribePet(principal.userId(), routineId, petId);
    }

    @DeleteMapping("/routines/{routineId}/pets/{petId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void unsubscribePet(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @PathVariable Long petId) {
        routineService.unsubscribePet(principal.userId(), routineId, petId);
    }

    // -------------------------------------------------------------------------
    // Pet-view: routines with subscription status
    // -------------------------------------------------------------------------

    @GetMapping("/pets/{petId}/routines")
    public ApiResponse<List<RoutineService.RoutineWithSubscriptionResponse>> listRoutinesForPet(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(routineService.listRoutinesForPet(principal.userId(), petId));
    }

    // -------------------------------------------------------------------------
    // Routine completion
    // -------------------------------------------------------------------------

    @PostMapping("/routines/{routineId}/complete/batch")
    public ApiResponse<List<RoutineLogResponse>> completeBatch(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @RequestBody RoutineCompleteBatchRequest req) {
        return ApiResponse.ok(routineService.completeBatch(principal.userId(), routineId, req));
    }

    @PostMapping("/routines/{routineId}/complete/individual")
    public ApiResponse<RoutineLogResponse> completeIndividual(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @Valid @RequestBody RoutineCompleteIndividualRequest req) {
        return ApiResponse.ok(routineService.completeIndividual(principal.userId(), routineId, req));
    }

    // -------------------------------------------------------------------------
    // Routine logs
    // -------------------------------------------------------------------------

    @GetMapping("/routines/{routineId}/logs")
    public ApiResponse<List<RoutineLogResponse>> listLogs(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.listLogs(principal.userId(), routineId));
    }

    @DeleteMapping("/routine-logs/{logId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteLog(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long logId) {
        routineService.deleteLog(principal.userId(), logId);
    }
}
