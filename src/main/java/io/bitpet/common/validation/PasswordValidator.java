package io.bitpet.common.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class PasswordValidator implements ConstraintValidator<ValidPassword, String> {

    private static final int MIN_LENGTH = 10;

    @Override
    public boolean isValid(String password, ConstraintValidatorContext context) {
        if (password == null || password.length() < MIN_LENGTH) {
            return false;
        }
        int typeCount = 0;
        if (password.chars().anyMatch(Character::isLetter)) typeCount++;
        if (password.chars().anyMatch(Character::isDigit)) typeCount++;
        if (password.chars().anyMatch(c -> !Character.isLetterOrDigit(c))) typeCount++;
        return typeCount >= 2;
    }
}
