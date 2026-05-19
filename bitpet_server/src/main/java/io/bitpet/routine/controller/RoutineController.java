package io.bitpet.routine.controller;

import io.bitpet.auth.jwt.AuthPrincipal;
import io.bitpet.common.response.ApiResponse;
import io.bitpet.routine.dto.AlarmCreateRequest;
import io.bitpet.routine.dto.AlarmResponse;
import io.bitpet.routine.dto.AlarmUpdateRequest;
import io.bitpet.routine.dto.RoutineCreateRequest;
import io.bitpet.routine.dto.RoutineResponse;
import io.bitpet.routine.dto.RoutineUpdateRequest;
import io.bitpet.routine.service.RoutineService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
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
    // Routine endpoints (nested under /pets/{petId})
    // -------------------------------------------------------------------------

    @GetMapping("/pets/{petId}/routines")
    public ApiResponse<List<RoutineResponse>> listRoutines(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId) {
        return ApiResponse.ok(routineService.listRoutines(principal.userId(), petId));
    }

    @GetMapping("/pets/{petId}/routines/{routineId}")
    public ApiResponse<RoutineResponse> getRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.getRoutine(principal.userId(), petId, routineId));
    }

    @PostMapping("/pets/{petId}/routines")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<RoutineResponse> createRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @Valid @RequestBody RoutineCreateRequest req) {
        return ApiResponse.ok(routineService.createRoutine(principal.userId(), petId, req));
    }

    @PutMapping("/pets/{petId}/routines/{routineId}")
    public ApiResponse<RoutineResponse> updateRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long routineId,
            @Valid @RequestBody RoutineUpdateRequest req) {
        return ApiResponse.ok(routineService.updateRoutine(principal.userId(), petId, routineId, req));
    }

    @DeleteMapping("/pets/{petId}/routines/{routineId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long routineId) {
        routineService.deleteRoutine(principal.userId(), petId, routineId);
    }

    @PatchMapping("/pets/{petId}/routines/{routineId}/execute")
    public ApiResponse<RoutineResponse> executeRoutine(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long petId,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.executeRoutine(principal.userId(), petId, routineId));
    }

    // -------------------------------------------------------------------------
    // Alarm endpoints (nested under /routines/{routineId})
    // -------------------------------------------------------------------------

    @GetMapping("/routines/{routineId}/alarms")
    public ApiResponse<List<AlarmResponse>> listAlarms(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId) {
        return ApiResponse.ok(routineService.listAlarms(principal.userId(), routineId));
    }

    @PostMapping("/routines/{routineId}/alarms")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AlarmResponse> addAlarm(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @Valid @RequestBody AlarmCreateRequest req) {
        return ApiResponse.ok(routineService.addAlarm(principal.userId(), routineId, req));
    }

    @PutMapping("/routines/{routineId}/alarms/{alarmId}")
    public ApiResponse<AlarmResponse> updateAlarm(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @PathVariable Long alarmId,
            @Valid @RequestBody AlarmUpdateRequest req) {
        return ApiResponse.ok(routineService.updateAlarm(principal.userId(), routineId, alarmId, req));
    }

    @DeleteMapping("/routines/{routineId}/alarms/{alarmId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAlarm(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long routineId,
            @PathVariable Long alarmId) {
        routineService.deleteAlarm(principal.userId(), routineId, alarmId);
    }
}
