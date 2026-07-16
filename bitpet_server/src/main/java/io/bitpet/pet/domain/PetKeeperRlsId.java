package io.bitpet.pet.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Embeddable
@Getter
@EqualsAndHashCode
@NoArgsConstructor
@AllArgsConstructor
public class PetKeeperRlsId implements Serializable {

    @Column(name = "pet_id")
    private Long petId;

    @Column(name = "user_id")
    private Long userId;
}
