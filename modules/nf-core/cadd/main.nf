process CADD {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "docker.io/paalmbj/cadd-with-envs:1.7.1"

    containerOptions {
        (workflow.containerEngine == 'singularity') ?
            "-B ${annotation_dir}/:/opt/CADD-scripts-1.7.1/data/annotations -B ${annotation_dir}/:$workDir/data/annotations" :
            "-v ${annotation_dir}/:/opt/CADD-scripts-1.7.1/data/annotations"
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
    def VERSION = "1.7.1" // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    """
    # Make sure cache directory at XDG_CACHE_HOME,  used by snakemake, is writable
    mkdir .snakemake_cache
    export XDG_CACHE_HOME=\$PWD/.snakemake_cache

    # Link CADD data for use with esm, expected at PWD/data
    ln -s /opt/CADD-scripts-1.7.1/data

    CADD.sh \\
        -o ${prefix}.tsv.gz \\
	-m -d \\
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
    def VERSION = "1.7.1" // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    """
    touch ${prefix}.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cadd: $VERSION
    END_VERSIONS
    """
}
