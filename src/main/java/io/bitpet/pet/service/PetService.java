package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.Pet;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.dto.PetUpdateRequest;
import io.bitpet.pet.repository.PetRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetService {

    private final PetRepository petRepository;
    private final SerialNumberGenerator serialNumberGenerator;

    @Transactional
    public PetResponse create(Long ownerId, PetCreateRequest request) {
        String serial = serialNumberGenerator.generate();
        Pet pet = Pet.builder()
                .serialNumber(serial)
                .ownerId(ownerId)
                .name(request.name())
                .species(request.species())
                .breed(request.breed())
                .birthDate(request.birthDate())
                .gender(request.gender())
                .build();
        return PetResponse.from(petRepository.save(pet));
    }

    public PetResponse get(Long ownerId, Long petId) {
        Pet pet = loadOwnedPet(ownerId, petId);
        return PetResponse.from(pet);
    }

    public List<PetResponse> listByOwner(Long ownerId) {
        return petRepository.findAllByOwnerId(ownerId).stream()
                .map(PetResponse::from)
                .toList();
    }

    @Transactional
    public PetResponse update(Long ownerId, Long petId, PetUpdateRequest request) {
        Pet pet = loadOwnedPet(ownerId, petId);
        pet.updateProfile(request.name(), request.breed(), request.birthDate(), request.gender());
        return PetResponse.from(pet);
    }

    @Transactional
    public void delete(Long ownerId, Long petId) {
        Pet pet = loadOwnedPet(ownerId, petId);
        petRepository.delete(pet);
    }

    private Pet loadOwnedPet(Long ownerId, Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getOwnerId().equals(ownerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "You do not own this pet");
        }
        return pet;
    }
}
