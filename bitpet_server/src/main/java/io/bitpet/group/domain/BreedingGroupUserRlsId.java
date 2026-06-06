package io.bitpet.group.domain;

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
public class BreedingGroupUserRlsId implements Serializable {

    @Column(name = "group_id")
    private Long groupId;

    @Column(name = "user_id")
    private Long userId;
}
