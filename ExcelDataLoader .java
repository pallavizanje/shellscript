package com.example.excelmatcher.config;

import com.example.excelmatcher.model.Record;
import jakarta.annotation.PostConstruct;
import org.apache.poi.ss.usermodel.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Configuration
public class ExcelDataLoader {

    @Value("classpath:policies.xlsx")
    private Resource excelFile;

    private final List<Record> cachedRecords = new ArrayList<>();

    public List<Record> getRecords() {
        return cachedRecords;
    }

    @PostConstruct
    void init() throws Exception {
        try (InputStream in = excelFile.getInputStream();
             Workbook wb = WorkbookFactory.create(in)) {

            Sheet sheet = wb.getSheetAt(0);               // first (or name it)
            for (Row row : sheet) {
                if (row.getRowNum() == 0) continue;       // skip header

                cachedRecords.add(new Record(
                        get(row, 0),  // id
                        get(row, 1),  // title
                        get(row, 2),  // description
                        get(row, 3),  // name
                        get(row, 4)   // gpn
                ));
            }
        }
        System.out.println("Loaded " + cachedRecords.size() + " records from Excel.");
    }

    private String get(Row row, int cellIdx) {
        Cell c = row.getCell(cellIdx, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        return c == null ? "" : c.toString().trim();
    }
}

package com.example.excelmatcher.service;

import org.apache.commons.text.similarity.JaroWinklerSimilarity;
import org.springframework.stereotype.Component;

@Component
public class SimilarityService {

    private final JaroWinklerSimilarity sim = new JaroWinklerSimilarity();

    /** 0.0‒1.0 */
    public double similarity(String a, String b) {
        return sim.apply(normalize(a), normalize(b));
    }

    private String normalize(String s) {
        return s == null ? "" : s.toLowerCase().replaceAll("[^a-z0-9 ]", " ");
    }
}


package com.example.excelmatcher.service;

import com.example.excelmatcher.config.ExcelDataLoader;
import com.example.excelmatcher.model.Record;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.Optional;

@Service
public class MatchService {

    private final ExcelDataLoader loader;
    private final SimilarityService similarity;

    public MatchService(ExcelDataLoader loader, SimilarityService similarity) {
        this.loader = loader;
        this.similarity = similarity;
    }

    public Optional<Record> bestMatch(String query, double threshold) {

        return loader.getRecords().stream()
                .map(r -> new Scored(r, score(query, r)))
                .max(Comparator.comparingDouble(s -> s.score))
                .filter(s -> s.score >= threshold)        // guard against weak matches
                .map(s -> s.record);
    }

    private double score(String query, Record r) {
        double t = similarity.similarity(query, r.title());
        double d = similarity.similarity(query, r.description());
        return Math.max(t, d);      // simple heuristic; refine as needed
    }

    private record Scored(Record record, double score) {}
}


package com.example.excelmatcher.controller;

import com.example.excelmatcher.model.Record;
import com.example.excelmatcher.service.MatchService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class MatchController {

    private final MatchService matchService;

    public MatchController(MatchService matchService) {
        this.matchService = matchService;
    }

    @PostMapping("/match")
    public ResponseEntity<?> match(@RequestBody List<String> queries,
                                   @RequestParam(defaultValue = "0.80") double threshold) {

        List<Map<String, Object>> result = new ArrayList<>();
        for (String q : queries) {
            Map<String, Object> row = matchService.bestMatch(q, threshold)
                    .<Map<String, Object>>map(r -> Map.of(
                            "query", q,
                            "id", r.id(),
                            "title", r.title(),
                            "description", r.description(),
                            "name", r.name(),
                            "gpn", r.gpn()
                    ))
                    .orElseGet(() -> Map.of(
                            "query", q,
                            "match", "NOT_FOUND"
                    ));
            result.add(row);
        }
        return new ResponseEntity<>(result, HttpStatus.OK);
    }
}




