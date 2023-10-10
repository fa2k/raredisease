process CADD {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::cadd-scripts=1.6 anaconda::conda=4.14.0 conda-forge::mamba=1.4.0"
    container 'paalmbj/cadd:1.6'

    containerOptions {
        (workflow.containerEngine == 'singularity') ?
            "--env XDG_CACHE_HOME=/tmp/.cache -B ${annotation_dir}/ref/CADD-v1.6:/opt/conda/share/cadd-scripts-1.6-1/data/annotations" :
            "--privileged -v ${annotation_dir}:/opt/conda/share/cadd-scripts-1.6-1/data/annotations"
        }

    input:
    tuple val(meta), path(vcf)
    path(annotation_dir)

    output:
    tuple val(meta), path("*.tsv.gz"), emit: tsv
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = "1.6" // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    """
    cadd.sh \\
        -o ${prefix}.tsv.gz \\
        $args \\
        $vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cadd: $VERSION
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = "1.6" // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    """
    touch ${prefix}.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cadd: $VERSION
    END_VERSIONS
    """
}
