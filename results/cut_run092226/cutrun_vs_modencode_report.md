# H3K4me3 CUT&RUN vs. C. elegans modENCODE — run cut_run092226

Two libraries, **S12** and **S13** (labelled "Beads"; two bead conditions of the same
H3K4me3 CUT&RUN), aligned to **ce11 / WBcel235** with bowtie2 `--very-sensitive -X 500`,
Picard-deduplicated, MAPQ ≥ 10. Pipeline as delivered stopped at bigWig; peak calling and
all reference comparisons below were added here.

**Headline:** S12 behaves like a working H3K4me3 CUT&RUN — it recovers ~80% of modENCODE
H3K4me3 domains and shows a sharp 4.3-fold promoter peak. S13 is the same experiment at
roughly a third of the specificity: same number of peaks, but much narrower, much weaker,
and only ~55% concordance with modENCODE.

![Main comparison]({{artifact:art_d193ef51-313d-48d3-9c92-5ffec04dc775}})

---

## 1. Library QC

| | S12 | S13 |
|---|---|---|
| raw read pairs | 36.5 M | 21.1 M |
| aligned pairs examined (Picard) | 34.9 M | 20.3 M |
| duplication rate | 26.4% | 19.6% |
| of which optical | 51.2% | 27.3% |
| reads after dedup + MAPQ10 | 49.2 M | 30.4 M |
| properly paired | **78.6%** | 93.0% |
| MACS2 fragment size | 215 bp | 187 bp |
| genome bases covered | 98.9% | 98.3% |
| CV of 1 kb-bin coverage | **1.22** | 0.68 |
| signal in top 1% of 1 kb bins | **6.8%** | 2.8% |
| chrX / autosome signal | **0.63** | 1.05 |
| chrM / autosome signal | 3.9 | 2.6 |

Two things stand out. S12's **21% discordant pairs** (mates on different chromosomes) is
high and worth tracking down — it is not a coverage problem, but it inflates the SAM and
indicates chimeric library molecules. Conversely S12's **higher coverage dispersion** is
the good kind: it is what specific enrichment looks like. S13's near-uniform coverage
(CV 0.68, 2.8% of signal in the top 1% of bins, flat across chromosomes) is what a
low-efficiency CUT&RUN looks like.

The **chrX depletion in S12 (0.63×)** is itself evidence of real H3K4me3: the *C. elegans*
X chromosome is gene-poor in highly expressed somatic genes and carries less active
chromatin. S13 shows no such depletion (1.05×), i.e. no chromosome-level structure at all.

## 2. Reference data used

modENCODE histone-modification data is not on the ENCODE portal for *C. elegans*, so
H3K4me3 references were taken from GEO and lifted from WormBase WS190 to ce11
(>99.9% of features mapped):

- **GSE28770** — modENCODE H3K4me3, N2 L3, ChIP-seq MACS peaks, 2 replicates
  (4,407 + 3,276 peaks → 4,657-feature union, 7.5% of genome)
- **GSE24318** — modENCODE H3K4me3, N2 mixed embryo, 2 replicates
  (3,811 + 3,487 peaks → 3,897-feature union, 11.5% of genome)

As an orthogonal promoter reference, **474 uniformly ce11-processed optimal-IDR peak sets**
(283 distinct targets; 129 modENCODE + 345 modERN TF ChIP-seq experiments) were pulled
from the ENCODE portal. These are narrow (median 420 bp) and centred on regulatory
elements, so they resolve promoter enrichment better than the broad 2010-era H3K4me3
domains.

## 3. Enrichment at modENCODE sites

Median log2(signal in peak / signal in matched ±10 kb flanks):

| reference | S12 | S13 |
|---|---|---|
| modENCODE H3K4me3 L3 rep1 | **1.55** (2.9×) | 0.47 (1.4×) |
| modENCODE H3K4me3 L3 rep2 | **1.67** (3.2×) | 0.52 (1.4×) |
| modENCODE H3K4me3 embryo rep1 | 1.24 (2.4×) | 0.30 (1.2×) |
| modENCODE H3K4me3 embryo rep2 | 1.38 (2.6×) | 0.36 (1.3×) |
| 474 TF peak sets (median across sets) | **1.97** (3.9×) | 0.71 (1.6×) |

S12 exceeds 2-fold over local background at 58.5–70.9% of individual modENCODE H3K4me3
peaks (67.5–70.9% for the L3 sets, 58.5–63.2% for the mixed-embryo sets); S13 at only
5.1–13.3% (12–13% L3, 5–6% mixed embryo). Across the 474 TF peak sets, S12 clears 2-fold in **96%** of sets
versus **0.2%** for S13 (panel b). The enrichment is essentially uniform across all 283
targets — expected, since worm TF ChIP-seq peaks are overwhelmingly promoter-proximal and
H3K4me3 marks the same promoters. That the TF sets give a *higher* ratio than the H3K4me3
sets reflects their narrower width, not a stronger biological relationship.

## 4. TSS metaprofile

Using WS245 gene models (46,712 genes with a TSS), split by whether the TSS falls inside
a modENCODE L3 H3K4me3 peak (12.5% do):

| | S12 | S13 |
|---|---|---|
| peak signal at marked TSS | **4.28× genome mean** | 1.59× |
| position of maximum | −175 bp | −175 bp |
| marked / unmarked TSS ratio | **4.92** | 1.62 |
| signal at unmarked TSS | 0.87× | 0.98× |

S12 gives the canonical H3K4me3 shape — sharp, promoter-centred, and *absent* at unmarked
TSS (0.88×, i.e. slightly below genome average). This is the cleanest single piece of
evidence that S12 is genuine H3K4me3 rather than accessibility background: an artefact
would elevate both classes. S13's marked/unmarked ratio of 1.62 means it retains real but
heavily diluted signal.

Averaged over *all* annotated TSS without stratification the enrichment is only 1.31×
(S12) — WS245 includes many non-coding and non-expressed genes, so the unstratified
profile is not a useful QC metric in worm.

## 5. Peak-level concordance

MACS2 `callpeak -f BAMPE -g 9e7 -q 0.01 --keep-dup all`, no IgG control available.
SEACR was attempted first but is unusable on the delivered HOMER bedGraphs — their
coverage is continuous genome-wide (98–99% of bases non-zero), so SEACR's zero-gap
segmentation merged everything into 33–39 megabase-scale blocks.

| | S12 | S13 |
|---|---|---|
| peaks called | 9,037 | 8,916 |
| mean width | **1,001 bp** | 397 bp |
| genome covered | 9.0% | 3.5% |

| comparison | % of reference recovered | Jaccard | fold vs. shuffled |
|---|---|---|---|
| S12 vs modENCODE H3K4me3 L3 | **79.4%** | 0.369 | 3.9 |
| S12 vs modENCODE H3K4me3 embryo | **81.4%** | 0.319 | 3.0 |
| S13 vs modENCODE H3K4me3 L3 | 52.3% | 0.148 | 4.1 |
| S13 vs modENCODE H3K4me3 embryo | 57.6% | 0.107 | 3.0 |
| S12 vs modENCODE+modERN TF union | 25.1% | 0.215 | 1.8 |
| S13 vs modENCODE+modERN TF union | 14.5% | 0.086 | 1.9 |
| S12 vs S13 | 61.2% | 0.219 | — |

89.7% of S12's peaks fall inside the modENCODE/modERN TF peak union (23.1% of the genome),
against 68.1% for S13. Only 61% of S13's peaks are shared with S12 despite the near-equal
peak counts, so the two bead conditions are not interchangeable replicates.

## 6. Tissue-specific expression (Serizay et al. 2020 FACS classes)

`All_tissues.xlsx` supplies 16 sheets of WormBase gene IDs from the Serizay/Ahringer
FACS tissue-expression classification. 99.5–99.9% of IDs in each sheet map to a ce11
`ws245Genes` TSS; `Intestine_only` and `Neurons_only` share zero genes.

H3K4me3 at TSS ±500 bp, fold over each track's genome mean:

| gene set | n TSS | S12 | S13 |
|---|---|---|---|
| ubiquitous | 3,389 | **3.36** | 1.34 |
| intestine only | 969 | **1.27** | 1.24 |
| neuron only | 840 | **0.74** | 1.03 |
| all annotated genes | 46,692 | 1.18 | 1.01 |

S12 signal scales with breadth of expression. Intestine-only promoters carry a real,
sharp peak (1.27×, maximum at −125 bp); neuron-only promoters of near-identical set
size are **depleted** (0.74×, no peak). All folds in this report use a single divisor per
track: the bigWig header `sumData / nBasesCovered` (`tables/track_genome_means.csv`). S13 ranks the classes in the same order but
compresses them to within noise.

## 7. Tissue-resolved ATAC (GSE141210) — the neuron result is a detection limit

Chromatin accessibility from FACS-sorted nuclei, same study. Processed bigWigs are
already on ce11 with UCSC naming and all normalised to the same total signal
(`sumData` 1.5 × 10⁸), so they are directly comparable to each other and need no lifting.

Fold enrichment at TSS ±500 bp, each track against its own genome mean:

| track | ubiquitous | intestine only | neuron only | all genes |
|---|---|---|---|---|
| intestine ATAC r1 | 1.99 | **2.35** | 0.68 | 1.29 |
| intestine ATAC r2 | 2.31 | **2.40** | 0.66 | 1.32 |
| neuron ATAC r1 | 2.25 | 0.65 | **1.91** | 1.31 |
| neuron ATAC r2 | 1.95 | 0.75 | **1.68** | 1.24 |
| germline ATAC r1 | 2.12 | 0.87 | 0.87 | 1.21 |
| S12 H3K4me3 (whole worm) | 3.36 | 1.27 | **0.74** | 1.18 |

The ATAC is cleanly reciprocal: intestine nuclei are open at intestine-only promoters
and closed at neuron-only ones, neuron nuclei the exact inverse, and germline nuclei sit
at background for both somatic sets. **Neuron-only promoters are therefore genuinely
accessible and active in neurons**, at a fold comparable to intestine-only promoters in
intestine — yet whole-worm S12 reads them below genome mean.

This makes the neuron result a measurement limit, not biology: ~20 large polyploid
intestinal cells contribute far more chromatin to a whole-animal prep than 302 small
diploid neurons. It also cross-validates the workbook's class assignments, since two
independently generated data types agree on which promoters belong to which tissue.

Caveat: the germline row uses a single replicate (rep1 only) — treat it as indicative,
not a measured contrast.

## 8. S12 overlaid on tissue ATAC

Per-gene promoter signal (TSS ±500 bp, fold over genome mean), Spearman ρ against S12:

| gene set | ρ(S12, intestine ATAC) | ρ(S12, neuron ATAC) |
|---|---|---|
| intestine only (n=970) | **+0.53** | +0.15 |
| neuron only (n=840) | +0.22 | +0.23 |
| ubiquitous (n=3,389) | +0.62 | +0.59 |

Within intestine-only genes S12 tracks intestine accessibility specifically — ρ = +0.53
versus +0.15 for neuron accessibility at the same promoters. Within neuron-only genes
the two correlations are equal and weak (+0.22 / +0.23), i.e. S12 carries no
neuron-specific information. For ubiquitous genes both are high and near-equal, as
expected when the promoter is open in every tissue.

The locus panels in Figure 4 show the same thing directly: at the intestine-only locus
`T09A12.4`, the intestine ATAC peak, the S12 H3K4me3 maximum and the TSS coincide; at
the neuron-only locus `K07A9.2` the neuron ATAC peak is the strongest in the window
(120× genome mean) while S12 stays flat at background across the whole 12 kb.

## 9. TES and metagene analysis on long genes

### Why a length filter is mandatory

The ws245 gene set has a **median length of 198 bp** and a 25th percentile of 21 bp:
**15,411 of 46,712 entries are exactly 21 bp**, i.e. the 21U-RNA (piRNA) loci, which are
a third of the annotation. A ±3 kb window around the TES would contain the TSS for
**86.6% of entries**, making an unfiltered TES profile meaningless — and this is also why
the unstratified "all genes" TSS profile in §4 is so flat (1.18×): it is mostly 21-bp
piRNA loci, not genes.

Long genes were therefore defined from the two named reference genes, whose spans were
confirmed against both NCBI Gene and the ws245 annotation:

| gene | sequence name | locus | span (ws245) | span (NCBI) |
|---|---|---|---|---|
| *pcaf-1* | Y47G6A.6 | chrI | 6,910 bp | 6,969 bp |
| *ama-1* | F36A4.7 | chrIV | 10,104 bp | 10,100 bp |

Threshold: **≥ 6.9 kb**, so *pcaf-1* itself qualifies. This yields 1,649 genes
(median 9.8 kb, 90th percentile 19.1 kb), of which **1,648 were profiled** — one gene's
±3 kb flank runs off a chromosome end and was excluded. All n below are profiled counts. At this length the ±3 kb TSS and TES windows
cannot overlap. Both named genes fall in the `Ubiquitous` class.

Set sizes (profiled): 418 with a modENCODE-marked promoter, 1,230 unmarked,
372 ubiquitous, 109 neuron-only, 74 intestine-only.

### Result

Fold over track genome mean, averaged over anchor ±500 bp:

| track | gene set | TSS | TES | TSS/TES |
|---|---|---|---|---|
| S12 H3K4me3 | modENCODE-marked promoter | **2.93** | 0.96 | **3.05** |
| S12 H3K4me3 | unmarked promoter | 0.97 | 0.86 | 1.12 |
| S12 H3K4me3 | ubiquitous | 2.42 | 1.03 | 2.35 |
| S12 H3K4me3 | all long genes | 1.47 | 0.89 | 1.65 |
| S13 H3K4me3 | modENCODE-marked promoter | 1.19 | 0.79 | 1.51 |
| S13 H3K4me3 | all long genes | 0.99 | 0.87 | 1.14 |
| intestine ATAC | intestine only | 2.35 | 1.42 | 1.65 |
| neuron ATAC | neuron only | 3.10 | 0.79 | 3.94 |
| germline ATAC | all long genes | 1.23 | 1.17 | 1.06 |

**S12 H3K4me3 is promoter-restricted.** At marked promoters it reaches 2.93× at the TSS
and falls to 0.96× — i.e. genome average — at the TES, a 3.05-fold asymmetry. The scaled
metagene shows the same shape: signal peaks just upstream of the TSS, drops through the
gene body to a **minimum of 0.64–0.68×** (below background), and returns to ~1.0× past
the TES. This is the expected distribution for H3K4me3 and is a useful internal
specificity control: a track dominated by generic accessibility or chromatin-openness
background would not show a 3-fold TSS/TES asymmetry.

**S13 again ranks correctly but compresses.** Its TSS/TES ratio at marked promoters is
1.51 versus S12's 3.05, and its metagene is nearly flat across the whole window.

Two observations that are not conclusions:

- **Germline ATAC is the only track with TES ≈ TSS** (1.17 vs 1.23, and 1.44 at
  ubiquitous TES — the highest TES value of any track). This may reflect the distinct
  regulatory architecture of germline genes reported by Serizay et al., but it rests on
  a single replicate here and was not tested.
- The intestine-only (n=74) and neuron-only (n=109) long-gene traces are visibly noisy
  in the metagene panels. That is small-n scatter across 100 body bins, not structure;
  the anchor values in the table are the reliable readout for those classes.

### Gene-length series: 2–4 kb, 4–6 kb, >6 kb

Repeating the TSS/TES comparison with genes split by length, using **±2 kb windows** so
that a 2 kb gene places its opposite anchor exactly at the window edge rather than inside
it (a ±3 kb window would place it 1 kb inside). All annotated genes in each bin, and
separately those whose promoter overlaps a modENCODE H3K4me3 peak:

| sample | gene set | length bin | n | TSS | TES | TSS/TES |
|---|---|---|---|---|---|---|
| S12 | all | 2–4 kb | 6,087 | 1.63 | 1.14 | 1.43 |
| S12 | all | 4–6 kb | 1,984 | 1.68 | 1.01 | 1.67 |
| S12 | all | >6 kb | 2,095 | 1.48 | 0.91 | 1.62 |
| S12 | marked promoter | 2–4 kb | 1,686 | 3.37 | 1.75 | 1.92 |
| S12 | marked promoter | 4–6 kb | 699 | 3.04 | 1.29 | 2.36 |
| S12 | marked promoter | >6 kb | 742 | 2.59 | 1.02 | 2.53 |
| S13 | all | 2–4 kb | 6,087 | 1.15 | 1.03 | 1.11 |
| S13 | all | 4–6 kb | 1,984 | 1.10 | 0.95 | 1.16 |
| S13 | all | >6 kb | 2,095 | 1.01 | 0.88 | 1.14 |
| S13 | marked promoter | >6 kb | 742 | 1.19 | 0.86 | 1.39 |

**The apparent TES signal in short genes is promoter bleed-through, not 3′ enrichment.**
For S12 at marked promoters, TES-proximal signal falls 1.75 → 1.29 → 1.02 across the three
bins while the TSS value changes little (3.37 → 3.04 → 2.59). The TSS/TES ratio therefore
rises monotonically with length (1.92 → 2.36 → 2.53). Only above 6 kb does the TES reach
genome average; in the all-genes series it is already at background (1.01) by 4–6 kb.

The TSS peak is also slightly *lower* for >6 kb genes (1.48) than for 2–4 kb genes (1.63)
in the all-genes series. In a genome this dense, a ±2 kb TSS window around a short gene
frequently contains a neighbouring gene's promoter, which inflates the short-gene value —
the same bleed-through acting in the other direction.

Practical consequence: **any TES or 3′ claim from this data should be restricted to genes
>6 kb**, and the gene-length distribution should be reported alongside any metaprofile.

Figure 9 note: all four panels share **one y scale, 0.63–2.10** (fold over genome mean), and
one x range −2 to +2 kb, with tick labels printed on every panel. The scale is set from the
data: the full range across all twelve curves is 0.664–2.030, so nothing is clipped and no
panel is autoscaled. Every curve in the figure is therefore directly comparable by eye.
The cost is that panels c and d occupy only the lower third of the axis — that emptiness is
the result (S13 is weak; TES signal is near background), not a layout fault. Per-column
scales were tried and rejected: they made the TES length separation easier to read but
invited a false visual comparison between columns.

## 10. Test for ATAC-type (accessibility) contamination

pAG-MNase liberates accessible chromatin regardless of the antibody, so a CUT&RUN track
can acquire an ATAC-like component. Two independent diagnostics were applied.

### Test 1 — signal at accessible sites that carry no H3K4me3

Accessible sites were called from the Serizay intestine and neuron ATAC tracks (300 bp
bins, max of the two tissues, ≥4× genome mean, merged within 200 bp, width ≥200 bp →
7,315 sites). These were classified by distance to the nearest annotated TSS (all 46,712,
including piRNA loci, so "distal" is conservative) and by overlap with an H3K4me3-marked
union (modENCODE L3 + mixed embryo + S12 MACS2 peaks; 9,295 features, 17.1 Mb):

- **557 distal unmarked accessible sites** (>2 kb from any TSS, no H3K4me3), median ATAC 6.0×
- **3,387 promoter-proximal marked accessible sites** (≤500 bp from a TSS, H3K4me3-positive), median ATAC 8.7×

The two classes differ only 1.45-fold in accessibility, so accessibility is close to
matched; what differs is the mark.

| track | marked accessible | unmarked accessible | ratio |
|---|---|---|---|
| **S12 H3K4me3** | **3.68×** | **1.01×** | **3.64** |
| S13 H3K4me3 | 1.77× | 1.16× | 1.53 |
| intestine ATAC | 6.74× | 2.89× | 2.33 |
| neuron ATAC | 8.51× | 6.06× | 1.40 |

S12 sits at **1.01× genome mean** — indistinguishable from background — at sites that are
6-fold accessible but unmarked, while the ATAC tracks report those same sites at 2.9× and
6.1×. Defining a **leakage index** as (unmarked − 1) / (marked − 1), the fraction of
enrichment attributable to accessibility alone:

- **S12: 0.4%**
- **S13: 20.5%**

Binning the unmarked distal sites by accessibility gives only a shallow trend for S12
(0.87× → 1.01× across a 3-fold accessibility range, ρ = +0.13); S13 shows none
(ρ = −0.07). So S12 has a weak but detectable accessibility dependence whose magnitude is
~0.14× genome mean at the most accessible sites — negligible against a 3.68× signal at
real targets.

### Test 2 — fragment-size distribution

Accessibility-derived fragments are subnucleosomal; nucleosome-bound fragments are
~150–180 bp. Distributions were computed from properly paired TLEN values, genome-wide and
within each region class.

| sample | region | n fragments | mode | median | <120 bp | 120–180 bp |
|---|---|---|---|---|---|---|
| S12 | genome-wide | 19.3 M | 169 | 182 | 17.5% | 31.8% |
| S12 | marked promoters | 1.78 M | 161 | 173 | 23.3% | 30.6% |
| S12 | distal unmarked accessible | 58 k | 168 | 183 | 20.7% | 27.7% |
| S12 | random background | 61 k | 160 | 184 | 16.3% | 31.9% |
| S13 | genome-wide | 14.1 M | 157 | 169 | 5.4% | 56.1% |
| S13 | marked promoters | 629 k | 158 | 174 | 7.9% | 47.5% |
| S13 | distal unmarked accessible | 49 k | 157 | 172 | 5.6% | 53.2% |
| S13 | random background | 43 k | 155 | 170 | 5.1% | 55.8% |

Every compartment in both samples is **mononucleosomal** (mode 155–169 bp). There is no
subnucleosomal population at accessible sites — the critical observation, because
accessibility contamination would produce one. The modest short-fragment shoulder in S12
(~70 bp) is *highest at marked promoters* (23.3%) and lower at distal accessible sites
(20.7%), i.e. it tracks the H3K4me3 signal, consistent with the nucleosome-depleted region
of an active promoter rather than with generic accessibility.

**Caveat:** bowtie2 was run with `-X 500`, so fragments >500 bp were never recorded. The
subnucleosomal range is unaffected and the mononucleosomal peak is fully resolved, but the
">180 bp" column is truncated and di-nucleosome content is only partly captured.

### Verdict

**No meaningful ATAC-type contamination in S12.** Accessibility explains ~0.4% of its
enrichment, its fragments are mononucleosomal in every compartment, and it discriminates
marked from unmarked accessible sites by 3.6-fold.

**S13 is a different matter.** Its leakage index is 20.5% — a fifth of its (already weak)
enrichment sits at accessible-but-unmarked sites — and it separates marked from unmarked
accessible sites by only 1.53-fold. Its fragments are nucleosomal and show no dose-response
to accessibility, so this is not classic ATAC-type contamination either; it reads as a high
floor of non-specific nucleosomal background diluting a weak specific signal. Note also
that S13's global subnucleosomal fraction (5.4%) is *lower* than S12's (17.5%), so
under-digestion rather than over-digestion.

## 11. GATA (ELT-2) binding sites

ELT-2 is the *C. elegans* intestinal GATA master regulator, so this is a directed test of
whether the intestine-only signal in §6–8 carries the expected regulatory grammar. Two
independent routes: the GATA-family ChIP peak sets already scored among the 474, and direct
WGATAA motif scanning against the ce11 genome.

### Motif enrichment

WGATAA (`[AT]GATAA`, both strands) counted in ce11. Genome-wide density is 1.689 per kb
(169,385 sites). Each class is compared to a width- and chromosome-matched shuffled control:

Figure 10a orders the classes reference-first — modENCODE ELT-2 ChIP, then the Ahringer
FACS promoter classes, then this run's peaks — with the two reference groups shaded and
bracketed as level-setters, and ELT-2 given its own hue (teal) so it is not confused with
the S12 purple used elsewhere in this report.

| region | per kb | vs shuffled |
|---|---|---|
| ELT-2 ChIP peaks (modENCODE, reference) | 4.31 | 2.53 |
| ubiquitous promoters (TSS ±250) | 1.68 | 1.03 |
| **intestine-only promoters** | **3.02** | **1.75** |
| neuron-only promoters | 1.59 | 0.94 |
| S12 H3K4me3 peaks (this run) | 2.00 | 1.20 |

ELT-2 ChIP peaks at 2.53x validates the motif definition. **GATA motif enrichment is
specific to intestine-only promoters (1.75x) and absent from both neuron-only (0.94x) and
ubiquitous (1.03x) promoters** - exactly the tissue restriction ELT-2 biology predicts, and
an independent confirmation of the Serizay class assignments from sequence alone.

S12's own peak set is only mildly GATA-enriched (1.20x), which is expected: H3K4me3 covers
all active promoters, and most of those are ubiquitous and GATA-free.

### S12 signal at GATA sites, and a metric caveat

| measure | value |
|---|---|
| S12 at all ELT-2 peaks | 3.12x genome mean |
| S12 at TSS-proximal ELT-2 peaks (<=500 bp) | 3.60x |
| S12 at distal ELT-2 peaks (>2 kb) | 1.97x |

**S12 is strongly enriched at GATA binding sites.** This corrects a misreading of the
flank-normalised table: by median log2(peak/flank) the ELT-2 sets rank 375-405 of 474
(log2 1.48-1.57), in the bottom quartile, which looks like weak signal. It is not. ELT-2
peaks are *more* promoter-proximal than the average TF peak set - median distance to the
nearest TSS 280 bp versus 804 bp, 60.2% versus 39.8% within 500 bp - so their +/-10 kb
flanks are themselves gene-dense and elevated, compressing the ratio. **For
promoter-proximal factors, read the fold-over-genome-mean, not the flank ratio.**

### GATA sites predict H3K4me3 within the intestinal set

Splitting the 970 intestine-only promoters by whether they contain a WGATAA site within
TSS +/-250 bp:

| | n | median S12 | mean S12 |
|---|---|---|---|
| no WGATAA | 211 | 0.99x | 1.18x |
| >=1 WGATAA | 759 | **1.33x** | 1.43x |

Mann-Whitney p = 1.1e-5. Intestinal promoters carrying a GATA site have measurably more
H3K4me3 than those without, and the no-motif group sits at exactly genome average. Within a
whole-worm prep whose intestinal signal is already diluted (section 7), the GATA-site subset
is where the detectable signal lives.

Not assessed: whether the motifs are the canonical extended ELT-2 site or the degenerate
form, motif positional distribution relative to the TSS, and the other GATA paralogues
individually (elt-1/3/4/7, med-1 and egl-27 peak-set values are in
`tables/gata_chip_peakset_enrichment.csv`).

## 12. Interpretation and next steps

S12 is usable for H3K4me3 biology as it stands. S13 is a weaker version of the same
experiment — it is not a failed library (its peaks are still 4× enriched over shuffled
expectation, and its properly-paired rate and duplication are actually *better* than S12),
but its signal-to-background is roughly a third of S12's. If the two bead conditions
differ in a protocol variable, that variable costs about two-thirds of the specific signal.

Not assessed: fragment-size distributions (informative for CUT&RUN — subnucleosomal vs.
mononucleosomal fractions), spike-in normalisation, and gene-level H3K4me3 versus
expression.

Worth doing next, in order:
1. **Chase the 21% discordant pairs in S12** — check the bowtie2 log for the mate-distance
   distribution and whether adapter trimming was complete.
2. **Run an IgG/no-antibody control through the same pipeline** and re-call peaks with
   `-c` — without it, MACS2's local-lambda model is the only background estimate, and the
   S13 numbers in particular would sharpen considerably.
3. **Developmental stage matching** — the modENCODE L3 reference agrees better with both
   samples than the mixed-embryo reference, but neither was matched to your staging.
   If the samples are not L3, the "% recovered" figures are conservative.

## Files

- `fig1_cutrun_vs_modencode.png` — QC and modENCODE concordance
- `fig2_tss_tissue_specific.png` — H3K4me3 at tissue-specific TSS
- `fig3_tissue_atac_vs_h3k4me3.png` — sorted-nuclei ATAC vs whole-worm H3K4me3
- `fig4_s12_atac_overlay.png` — S12 overlaid on tissue ATAC (loci + per-gene correlation)
- `atac_tss_summary.csv`, `atac_tss_profiles.csv` — ATAC enrichment and profile values
- `tss_tissue_summary.csv`, `tss_profile_by_tissue.csv` — tissue-class H3K4me3
- `promoter_signal_per_gene.csv` — per-gene promoter signal, all six tracks
- `locus_track_values.csv` — track values for the two Figure 4 loci
- `fig6_long_gene_tss_vs_tes.png` — TSS vs TES, long genes (≥6.9 kb)
- `fig7_long_gene_metagene.png` — scaled metagene, long genes
- `long_gene_anchor_summary.csv` — TSS/TES folds for every track × gene set
- `long_gene_{tss,tes,metagene}_profiles.csv` — profile values (fold over genome mean)
- `gene_tss_tes_table.csv` — per-gene TSS, TES, length and tissue class
- `fig8_atac_contamination_test.png` — accessibility-contamination diagnostics
- `contamination_verdict.csv` — leakage index, discrimination ratio, fragment stats
- `accessibility_leakage.csv` — signal at marked vs unmarked accessible sites, all tracks
- `fragment_size_summary.csv`, `fragment_size_histograms.csv` — fragment distributions
- `leakage_dose_response.csv` — per-site ATAC strength vs H3K4me3
- `qc_summary.csv` — per-sample library and coverage metrics
- `peak_overlap_modencode.csv` — all overlap/Jaccard/shuffle statistics
- `modencode_H3K4me3_enrichment.csv` — peak/flank enrichment at the four H3K4me3 sets
- `modencode_TF_peakset_enrichment.csv` — per-target enrichment across all 474 TF peak sets
- `tss_profile_stratified.csv` — TSS metaprofile values (50 bp bins, ±3 kb)
- `S12_MACS2_peaks_ce11.bed`, `S13_MACS2_peaks_ce11.bed` — called peaks
- `modENCODE_H3K4me3_L3_ce11.bed`, `modENCODE_H3K4me3_mixedEmbryo_ce11.bed` — lifted reference peaks
- `modENCODE_modERN_TF_peaksets_manifest.csv` — accessions and targets of the 474 ENCODE-portal peak sets
