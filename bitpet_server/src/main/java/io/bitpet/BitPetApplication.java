package io.bitpet;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackages = "io.bitpet")
@EnableJpaAuditing
public class BitPetApplication {

    public static void main(String[] args) {
        SpringApplication.run(BitPetApplication.class, args);
    }
}
