package io.bitpet.pet.dto;

import io.bitpet.pet.domain.Pet;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetSpecies;

import java.time.Instant;
import java.time.LocalDate;

public record PetResponse(
        Long id,
        String serialNumber,
        Long ownerId,
        String name,
        PetSpecies species,
        String breed,
        LocalDate birthDate,
        PetGender gender,
        Instant createdAt,
        Instant updatedAt
) {
    public static PetResponse from(Pet pet) {
        return new PetResponse(
                pet.getId(),
                pet.getSerialNumber(),
                pet.getOwnerId(),
                pet.getName(),
                pet.getSpecies(),
                pet.getBreed(),
                pet.getBirthDate(),
                pet.getGender(),
                pet.getCreatedAt(),
                pet.getUpdatedAt()
        );
    }
}
