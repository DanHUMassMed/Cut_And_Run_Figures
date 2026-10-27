# Methods

Analysis of the `cut_run092226` H3K4me3 CUT&RUN run against C. elegans modENCODE /
modERN reference data and Serizay et al. 2020 tissue-resolved data.
Analysis date: 2026-09-30. All coordinates ce11 / WBcel235.

## 1. Input data

Two libraries, **S12** (`L5936-0009-0012-Beads_S12_L003`) and **S13**
(`L5936-0009-0013-Beads_S13_L003`) — two bead conditions of the same H3K4me3 CUT&RUN.

Upstream processing was already complete on delivery and was not re-run. Read from
the SAM `@PG` headers:

| step | tool | version |
|---|---|---|
| alignment | bowtie2 `--very-sensitive -N 0 -X 500 -p 16` | 2.5.0 |
| duplicate removal | Picard MarkDuplicates `REMOVE_DUPLICATES=true` | 2.5.0 |
| MAPQ filter | `samtools view -h -q 10` | 1.16.1 |
| coverage | HOMER `makeUCSCfile`, normalised to 1e7 tags | — |

Inputs used here: `08_bigwig/*.bw` (signal), `05_mapq_filter/*_mapqfilt.sam`
(peak calling), `04_dedup/*_dup.txt` and `02_fastqc/*.html` (QC),
`All_tissues.xlsx` (tissue classes).

## 2. Reference data

**modENCODE / modERN TF peaks.** ENCODE portal query: `type=File`, `assembly=ce11`,
`file_format=bed`, `status=released`,
`output_type=optimal IDR thresholded peaks`. Returned 474 narrowPeak files
(129 modENCODE + 345 modERN, 283 distinct targets, all `whole organism`).
Accessions and targets in `tables/modENCODE_modERN_TF_peaksets_manifest.csv`.
A merged union (`reference/modTF_union.bed`, 41,560 features, 23.1% of the genome)
was built with `bedtools merge`.

**modENCODE H3K4me3 peaks.** C. elegans histone-modification data is not on the
ENCODE portal (`assay_title=Histone ChIP-seq` returns zero for this organism), so
peaks were taken from GEO and lifted:

- `GSE28770` — H3K4me3, N2 L3, ChIP-seq MACS 1.4, GSM713151 + GSM713152
  (4,410 + 3,282 peaks, GFF, WormBase WS190)
- `GSE24318` — H3K4me3, N2 mixed embryo, GSM599725 + GSM599726
  (3,811 + 3,487 peaks, BED)

GFF (Roman chromosome names, 1-based inclusive) was converted to BED by prefixing
`chr` and subtracting 1 from the start, then lifted WS190/ce6 -> ce11 with UCSC
`liftOver` and `ce6ToCe11.over.chain.gz`. Mapping was >99.9% complete
(1 of 4,408 and 4 of 3,280 features lost for the L3 replicates; 0 of 3,811 and
0 of 3,487 for mixed embryo). Per-stage unions were merged with `bedtools merge`
into `reference/modENCODE_H3K4me3_L3_ce11.bed` (4,657 features, 7.5% of genome)
and `reference/modENCODE_H3K4me3_mixedEmbryo_ce11.bed` (3,897 features, 11.5%).

**Tissue-resolved ATAC.** `GSE141210` (subseries of SuperSeries `GSE141213`;
Serizay et al. 2020, Genome Research) — ATAC-seq from FACS-sorted nuclei.
Processed bigWigs downloaded per GSM (not the 2 GB series tar):
GSM4197238 (germline pe rep1), GSM4197239 (neurons pe rep1),
GSM4197242 (intestine pe rep1), GSM4197244 (neurons pe rep2),
GSM4197247 (intestine pe rep2). All young adult, paired-end.
These are already ce11 with UCSC chromosome naming and all carry the same total
signal (`sumData` 1.5e8), so no lifting or rescaling was applied.

**Gene models.** `ws245Genes` from the UCSC REST API
(`api.genome.ucsc.edu/getData/track?genome=ce11;track=ws245Genes`), 57,791
transcripts collapsed to one TSS per WormBase gene ID (most 5' transcript),
46,712 genes with a TSS on chrI-chrV or chrX.

**Tissue classes.** `All_tissues.xlsx`, 16 sheets of WormBase gene IDs.
Sheets used: `Ubiquitous` (3,393 IDs), `Intestine_only` (974), `Neurons_only` (844).
Mapping to a ce11 TSS succeeded for 99.9% / 99.6% / 99.5% respectively;
`Intestine_only` and `Neurons_only` share zero genes.

## 3. Coverage and QC metrics

Genome-wide coverage was binned at 1 kb (`pyBigWig.stats`, `type='mean'`), chrM
excluded from all summary statistics. Reported: coefficient of variation of bin
signal, fraction of total signal in the top 0.1/1/5% of bins, per-chromosome means,
and the cumulative signal-concentration curve. Duplication and library-size metrics
were parsed from the Picard `_dup.txt` files; proper-pair rates from
`samtools flagstat` on the converted BAMs.

## 4. Enrichment at reference peaks

For each reference peak, mean bigWig signal in the peak was compared to mean signal
in two matched flanking windows of the same width, offset 10 kb upstream and
downstream, averaged. Windows narrower than 20 bp or running off a chromosome end
were dropped. The reported statistic is the **median log2(peak / flank)** across
peaks, plus the fraction of peaks reaching >=2x their flanks. The flank control
absorbs local mappability and chromatin-domain structure that a genome-mean
denominator does not. Applied to all four modENCODE H3K4me3 sets and independently
to each of the 474 TF peak sets (`code/enrich_at_modencode.py`, 12 processes).

## 5. TSS metaprofiles

Strand-oriented mean profiles from `pyBigWig.stats(..., nBins=)`; minus-strand genes
reversed. Windows: +/-3 kb at 50 bp for the stratified and tissue-class profiles,
+/-2 kb at 50 bp for the first ATAC pass, +/-6 kb at 25 bp for the locus panels.
Genes whose window ran off a chromosome end were excluded (19 of 46,712).

Profiles were stratified two ways: (i) by whether the TSS falls inside a modENCODE
L3 H3K4me3 peak, and (ii) by `All_tissues.xlsx` class. Stratification is essential —
WS245 includes many non-coding and non-expressed genes, and an unstratified profile
over all TSS flattens S12 to 1.19x. For cross-track comparison each profile was
divided by its own track's genome mean (`sumData / nBasesCovered`). This is the **single
divisor definition used for every fold value in this package** (tabulated in
`tables/track_genome_means.csv`); an earlier draft also used a 1 kb-bin mean, which
differs by ~1% — all outputs were regenerated on the header definition so tables agree. The `all genes`
reference line uses a seeded random subsample (n=5,000, `RandomState(0)`).

Per-gene promoter signal for the correlation analysis is the mean over TSS +/-500 bp,
expressed as fold over genome mean; association with ATAC reported as Spearman rho.

## 5b. TES and metagene profiles (long genes)

The ws245 gene set is unsuitable for unfiltered TES analysis: median entry length is
198 bp, the 25th percentile is 21 bp, and 15,411 of 46,712 entries are exactly 21 bp
(21U-RNA / piRNA loci). A +/-3 kb TES window contains the TSS for 86.6% of entries.

Long genes were defined as length >= 6,900 bp, chosen so that *pcaf-1* (Y47G6A.6,
6,910 bp in ws245; 6,969 bp per NCBI Gene) qualifies; *ama-1* (F36A4.7) is 10,104 bp.
n = 1,649 genes, median 9,824 bp; 1,648 were profiled (one gene's flank runs off a
chromosome end). Reported n are always the profiled counts from `long_gene_anchor_summary.csv`,
not the pre-filter set sizes. At this length the +/-3 kb TSS and TES windows cannot
overlap. TES = `txEnd` for + strand genes, `txStart` for - strand genes.

Point profiles at TSS and TES used the same method as section 5 (+/-3 kb, 50 bp bins,
strand-oriented). The scaled metagene concatenates 3 kb upstream in 60 bins of 50 bp,
the gene body resampled to 100 bins by `pyBigWig.stats(..., nBins=100)`, and 3 kb
downstream in 60 bins; minus-strand genes are reversed after concatenation. Genes whose
flanks ran off a chromosome end were excluded. All values are fold over the track's
genome mean (same divisor as elsewhere). Script: `code/long_gene_profiles.py`.

## 5c. Accessibility-contamination diagnostics

**Accessible-site definition.** Intestine and neuron ATAC (rep1) were binned at 300 bp,
each bin expressed as fold over that track's genome mean, and the per-bin maximum of the
two tissues taken. Bins >= 4x were merged within 200 bp (`bedtools merge -d 200`) and
filtered to width >= 200 bp: 7,315 sites. Distance to the nearest of all 46,712 annotated
TSS was computed with `bedtools closest -d` (all TSS, including 21U-RNA loci, so "distal"
is conservative). H3K4me3-marked status = overlap with the merged union of modENCODE L3,
modENCODE mixed-embryo and S12 MACS2 peaks (9,295 features, 17.1 Mb). Classes used:
distal (>2 kb) and unmarked, n=557; promoter-proximal (<=500 bp) and marked, n=3,387.

Site signal was scored as in section 4 (mean over site vs two matched +/-10 kb flanks) and
as fold over the track genome mean. The **leakage index** is (fold at unmarked accessible
- 1) / (fold at marked accessible - 1). Dose-response used ATAC-strength quartiles of the
557 unmarked distal sites and Spearman rho of per-site ATAC fold against H3K4me3 fold.

**Fragment sizes.** TLEN of properly paired, primary, non-supplementary alignments
(`samtools view -f 3 -F 3852`), positive values only, capped at 500 bp. Computed
genome-wide and with `-L` restriction to each region class; the random-background class is
`bedtools shuffle -noOverlapping -seed 7` of the distal unmarked set. Note bowtie2 ran with
`-X 500`, so fragments >500 bp were never recorded: the subnucleosomal range and the
mononucleosomal peak are fully resolved, but di-nucleosome content is truncated.

## 6. Peak calling

SEACR 1.3 was attempted first as the CUT&RUN-native caller and **rejected**: the
delivered HOMER bedGraphs have continuous non-zero coverage (98.9% and 98.3% of
genome bases), and SEACR delimits features by zero-coverage gaps, so it merged the
genome into 33 and 39 megabase-scale blocks. It exited successfully; the output was
unusable and was discarded.

MACS2 was used instead. The MAPQ-filtered, deduplicated SAM files were converted with
`samtools view -@ 6 -b` and indexed, then:

    macs2 callpeak -t <bam> -f BAMPE -g 9e7 -n <name> -q 0.01 --keep-dup all

`-g 9e7` is the effective ce11 genome size; `--keep-dup all` because Picard had
already removed duplicates. **No IgG or no-antibody control was available**, so
MACS2's local-lambda model is the only background estimate. MACS2 estimated fragment
sizes of 215.1 bp (S12) and 187.2 bp (S13).

## 7. Overlap statistics

`bedtools intersect -u` for feature counts in both directions, `bedtools jaccard`
for base-level similarity. The null expectation is the mean of 5 `bedtools shuffle
-noOverlapping` permutations (seeds 1-5) against `reference/ce11.genome`
(autosomes + X, chrM excluded), reported as `fold_vs_shuffled`.

## 8. Not assessed

Fragment-size distributions (subnucleosomal vs mononucleosomal fractions),
spike-in normalisation, H3K4me3 versus quantitative expression level, and
assumption or residual diagnostics. The germline ATAC contrast uses one replicate.

## 9. Software

| tool | version |
|---|---|
| python | 3.12.14 |
| pandas / numpy / scipy | 3.0.6 / 2.5.3 / 1.18.1 |
| matplotlib | 3.11.2 |
| pyBigWig | 0.3.26 |
| bedtools | 2.31.1 |
| samtools | 1.24 |
| MACS2 | 2.2.9.1 |
| SEACR | 1.3 (attempted, rejected) |
| UCSC liftOver | current release, 2026-09-30 |
| openpyxl | (xlsx reading) |

MACS2 was installed in a separate conda environment (python 3.11) because it pins
python <3.12.
