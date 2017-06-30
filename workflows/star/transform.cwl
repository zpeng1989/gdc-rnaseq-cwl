#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: Workflow

inputs:
  - id: genome_dir
    type: Directory
  - id: input_bam
    type: File
  - id: run_uuid
    type: string
  - id: thread_count
    type: int

requirements:
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement

outputs:
  []
  # - id: merge_all_sqlite_destination_sqlite
  #   type: File
  #   outputSource: merge_all_sqlite/destination_sqlite

steps:
  - id: picard_validatesamfile_original
    run: ../../tools/picard_validatesamfile.cwl
    in:
      - id: INPUT
        source: input_bam
      - id: VALIDATION_STRINGENCY
        valueFrom: "LENIENT"
    out:
      - id: OUTPUT

  # need eof and dup QNAME detection
  - id: picard_validatesamfile_original_to_sqlite
    run: ../../tools/picard_validatesamfile_to_sqlite.cwl
    in:
      - id: bam
        source: input_bam
        valueFrom: $(self.basename)
      - id: input_state
        valueFrom: "original"
      - id: metric_path
        source: picard_validatesamfile_original/OUTPUT
      - id: uuid
        source: run_uuid
    out:
      - id: sqlite

  - id: biobambam_bamtofastq
    run: ../../tools/biobambam2_bamtofastq.cwl
    in:
      - id: filename
        source: input_bam
    out:
      - id: output_fastq1
      - id: output_fastq2
      - id: output_fastq_o1
      - id: output_fastq_o2
      - id: output_fastq_s

  # - id: fastq_metrics
  #   run: fastq_metrics.cwl
  #   in:
  #     - id: fastq1
  #       source: biobambam_bamtofastq/output_fastq1
  #     - id: fastq2
  #       source: biobambam_bamtofastq/output_fastq2
  #     - id: fastq_o1
  #       source: biobambam_bamtofastq/output_fastq_o1
  #     - id: fastq_o2
  #       source: biobambam_bamtofastq/output_fastq_o2
  #     - id: fastq_s
  #       source: biobambam_bamtofastq/output_fastq_s
  #     - id: run_uuid
  #       source: run_uuid
  #     - id: thread_count
  #       source: thread_count
  #   out:
  #     - id: merge_fastq_metrics_destination_sqlite
        
  - id: bam_readgroup_to_json
    run: ../../tools/bam_readgroup_to_json.cwl
    in:
      - id: INPUT
        source: input_bam
      - id: MODE
        valueFrom: "lenient"
    out:
      - id: OUTPUT

  # - id: readgroup_json_db
  #   run: ../../tools/readgroup_json_db.cwl
  #   scatter: json_path
  #   in:
  #     - id: json_path
  #       source: bam_readgroup_to_json/OUTPUT
  #     - id: uuid
  #       source: run_uuid
  #   out:
  #     - id: log
  #     - id: output_sqlite

  # - id: merge_readgroup_json_db
  #   run: ../../tools/merge_sqlite.cwl
  #   in:
  #     - id: source_sqlite
  #       source: readgroup_json_db/output_sqlite
  #     - id: uuid
  #       source: run_uuid
  #   out:
  #     - id: destination_sqlite
  #     - id: log


  - id: star_pass_1
    run: ../../tools/star_pass_1.cwl
    in:
      - id: 


  # - id: merge_all_sqlite
  #   run: ../../tools/merge_sqlite.cwl
  #   in:
  #     - id: source_sqlite
  #       source: [
  #         picard_validatesamfile_original_to_sqlite/sqlite,
  #         merge_readgroup_json_db/destination_sqlite,
  #         fastq_metrics/merge_fastq_metrics_destination_sqlite
  #       ]
  #     - id: uuid
  #       source: run_uuid
  #   out:
  #     - id: destination_sqlite
  #     - id: log
