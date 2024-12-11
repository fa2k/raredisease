//
// Map to reference
//

include { SAMTOOLS_VIEW              } from '../../modules/nf-core/samtools/view/main'
include { ALIGN_MT                   } from './alignment/align_MT'
include { ALIGN_MT as ALIGN_MT_SHIFT } from './alignment/align_MT'
include { CONVERT_MT_BAM_TO_FASTQ    } from './mitochondria/convert_mt_bam_to_fastq'

workflow INPUT_ALIGNED {
    take:
        ch_aligned_and_index     // channel: [mandatory] [ val(meta), path(bam|cram), path(bai|crai) ]
        ch_genome_fasta          // channel: [mandatory] [ val(meta), path(fasta) ]
        ch_genome_fai            // channel: [mandatory] [ val(meta), path(fai) ]
        ch_genome_dictionary     // channel: [mandatory] [ val(meta), path(dict) ]
        ch_mt_bwaindex           // channel: [mandatory] [ val(meta), path(index) ]
        ch_mt_bwamem2index       // channel: [mandatory] [ val(meta), path(index) ]
        ch_mt_dictionary         // channel: [mandatory] [ val(meta), path(dict) ]
        ch_mt_fai                // channel: [mandatory] [ val(meta), path(fai) ]
        ch_mt_fasta              // channel: [mandatory] [ val(meta), path(fasta) ]
        ch_mtshift_bwaindex      // channel: [mandatory] [ val(meta), path(index) ]
        ch_mtshift_bwamem2index  // channel: [mandatory] [ val(meta), path(index) ]
        ch_mtshift_dictionary    // channel: [mandatory] [ val(meta), path(dict) ]
        ch_mtshift_fai           // channel: [mandatory] [ val(meta), path(fai) ]
        ch_mtshift_fasta         // channel: [mandatory] [ val(meta), path(fasta) ]

    main:
        ch_bwamem2_bam        = Channel.empty()
        ch_bwamem2_bai        = Channel.empty()
        ch_fastp_json         = Channel.empty()
        ch_mt_bam_bai         = Channel.empty()
        ch_mt_marked_bam      = Channel.empty()
        ch_mt_marked_bai      = Channel.empty()
        ch_mtshift_bam_bai    = Channel.empty()
        ch_mtshift_marked_bam = Channel.empty()
        ch_mtshift_marked_bai = Channel.empty()
        ch_sentieon_bam       = Channel.empty()
        ch_sentieon_bai       = Channel.empty()
        ch_versions           = Channel.empty()


        // if cram then convert it TODO
        /*input_sample_type = input_sample.branch{
            bam:   it[0].data_type == "bam"
            fastq: it[0].data_type == "fastq"
        }*/

        ch_genome_bam_bai = ch_aligned_and_index

        ch_aligned_and_index
                .map { meta, bam, bai -> [meta, bam] }
                .set { ch_genome_marked_bam }
        ch_aligned_and_index
                .map { meta, bam, bai -> [meta, bai] }
                .set { ch_genome_marked_bai }


        // PREPARING READS FOR MT ALIGNMENT
        if (params.analysis_type.matches("wgs|mito") || params.run_mt_for_wes) {
            CONVERT_MT_BAM_TO_FASTQ (
                ch_genome_bam_bai,
                ch_genome_fasta,
                ch_genome_fai,
                ch_genome_dictionary
            )

            ALIGN_MT (
                CONVERT_MT_BAM_TO_FASTQ.out.fastq,
                CONVERT_MT_BAM_TO_FASTQ.out.bam,
                ch_mt_bwaindex,
                ch_mt_bwamem2index,
                ch_mt_fasta,
                ch_mt_dictionary,
                ch_mt_fai
            )

            ALIGN_MT_SHIFT (
                CONVERT_MT_BAM_TO_FASTQ.out.fastq,
                CONVERT_MT_BAM_TO_FASTQ.out.bam,
                ch_mtshift_bwaindex,
                ch_mtshift_bwamem2index,
                ch_mtshift_fasta,
                ch_mtshift_dictionary,
                ch_mtshift_fai
            )

            ch_mt_marked_bam      = ALIGN_MT.out.marked_bam
            ch_mt_marked_bai      = ALIGN_MT.out.marked_bai
            ch_mt_bam_bai         = ch_mt_marked_bam.join(ch_mt_marked_bai, failOnMismatch:true, failOnDuplicate:true)
            ch_mtshift_marked_bam = ALIGN_MT_SHIFT.out.marked_bam
            ch_mtshift_marked_bai = ALIGN_MT_SHIFT.out.marked_bai
            ch_mtshift_bam_bai    = ch_mtshift_marked_bam.join(ch_mtshift_marked_bai, failOnMismatch:true, failOnDuplicate:true)
            ch_versions           = ch_versions.mix(ALIGN_MT.out.versions,
                                        ALIGN_MT_SHIFT.out.versions,
                                        CONVERT_MT_BAM_TO_FASTQ.out.versions)
        }

        if (params.save_mapped_as_cram) { // TODO handle cram in
            SAMTOOLS_VIEW( ch_genome_bam_bai, ch_genome_fasta, [] )
            ch_versions   = ch_versions.mix(SAMTOOLS_VIEW.out.versions)
        }

    emit:
        genome_marked_bam  = ch_genome_marked_bam  // channel: [ val(meta), path(bam) ]
        genome_marked_bai  = ch_genome_marked_bai  // channel: [ val(meta), path(bai) ]
        genome_bam_bai     = ch_genome_bam_bai     // channel: [ val(meta), path(bam), path(bai) ]
        mt_marked_bam      = ch_mt_marked_bam      // channel: [ val(meta), path(bam) ]
        mt_marked_bai      = ch_mt_marked_bai      // channel: [ val(meta), path(bai) ]
        mt_bam_bai         = ch_mt_bam_bai         // channel: [ val(meta), path(bam), path(bai) ]
        mtshift_marked_bam = ch_mtshift_marked_bam // channel: [ val(meta), path(bam) ]
        mtshift_marked_bai = ch_mtshift_marked_bai // channel: [ val(meta), path(bai) ]
        mtshift_bam_bai    = ch_mtshift_bam_bai    // channel: [ val(meta), path(bam), path(bai) ]
        versions           = ch_versions           // channel: [ path(versions.yml) ]
}
