FROM ubuntu:noble

LABEL description="methyl-data analysis pipeline version 2"
ENV TZ=Europe/Stockholm
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
  apt-get install -y \
  git \
  g++ \
  build-essential \
  openjdk-8-jdk \
  openjdk-8-jre \
  perl \
  wget \
  curl \
  cpanminus \
  zlib1g \
  zlib1g-dev \
  nano \
  tar \
  libtbb-dev \
  pigz \
  software-properties-common \
  libssl-dev \
  libbz2-dev \
  uuid-dev \
  samtools \
  bedtools \
  bowtie2 \
  trim-galore \
  fastqc \
  multiqc \
  cutadapt \
  bedops \
  libcurl4-gnutls-dev \
  libharfbuzz-dev \
  libfreetype6-dev \
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev \
  libfribidi-dev \
  libfontconfig1-dev \
  libxml2-dev \
  libhdf5-dev \
  hdf5-tools

# Install UCSC fasize from source
RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faSize
RUN chmod +x faSize
RUN mv faSize /usr/local/bin/
# Install UCSC wigToBigWig from source
RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig
RUN chmod +x wigToBigWig
RUN mv wigToBigWig /usr/local/bin/

RUN apt-get update && apt-get install -y software-properties-common && \
  wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | apt-key add - && \
  add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/' && \
  apt-get update && apt-get install -y \
  r-base-dev

# Set POSIT as the default CRAN repo
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))' >> /root/.Rprofile
# Set POSIT as the default CRAN and Bioconductor repository
RUN echo 'options(BioC_mirror = "https://packagemanager.posit.co/bioconductor/latest")' >> /root/.Rprofile && \
  echo 'options(BIOCONDUCTOR_CONFIG_FILE = "https://packagemanager.posit.co/bioconductor/latest/config.yaml")' >> /root/.Rprofile && \
  echo 'Sys.setenv("R_BIOC_VERSION" = "3.20")' >> /root/.Rprofile && \
  echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))' >> /root/.Rprofile
RUN R -e "install.packages('BiocManager', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest')"
RUN R -e "install.packages('XML', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(XML)"
RUN R -e "BiocManager::install('rtracklayer'); library(rtracklayer)"
# Remove data.table if it is already installed and install the version 1.14.8
RUN R -e "if('data.table' %in% rownames(installed.packages())) remove.packages('data.table')"
RUN R -e "install.packages('ragg', dependencies = TRUE, repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(ragg)"
RUN R -e "install.packages('devtools', dependencies = TRUE, repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(devtools)"
RUN R -e "devtools::install_version('data.table', version = '1.14.10', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(data.table)"
RUN R -e "BiocManager::install('methylKit'); library(methylKit)"
RUN R -e "BiocManager::install('BiocGenerics'); library(BiocGenerics)"
RUN R -e "BiocManager::install('S4Vectors'); library(S4Vectors)"
RUN R -e "BiocManager::install('Rhtslib'); library(Rhtslib)"
RUN R -e "BiocManager::install('IRanges'); library(IRanges)"
RUN R -e "BiocManager::install('GenomeInfoDb'); library(GenomeInfoDb)"
RUN R -e "BiocManager::install('GenomicRanges'); library(GenomicRanges)"
RUN R -e "BiocManager::install('Biostrings'); library(Biostrings)"
RUN R -e "BiocManager::install('BSgenome'); library(BSgenome)"
RUN R -e "BiocManager::install('MethylSeekR'); library(MethylSeekR)"
RUN R -e "BiocManager::install('HDF5Array', dependencies=TRUE); library(HDF5Array)"
RUN R -e "BiocManager::install('bsseq'); library(bsseq)"
RUN R -e "BiocManager::install('BiocParallel'); library(BiocParallel)"
RUN R -e "install.packages('circlize', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(circlize)"
RUN R -e "install.packages('MASS', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(MASS)"
RUN R -e "install.packages('stringi', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(stringi)"
RUN R -e "install.packages('ggplot2', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(ggplot2)"
RUN R -e "install.packages('gprofiler2', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(gprofiler2)"
RUN R -e "install.packages('doParallel', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(doParallel)"
RUN R -e "install.packages('foreach', repos='https://packagemanager.posit.co/cran/__linux__/noble/latest'); library(foreach)"

RUN cpanm \
      Math::Gauss \
      Math::Round \
      Bio::Trace::ABIF \
      Spreadsheet::Write \
			Statistics::Basic \
      Parallel::ForkManager \
	    Sort::Key

RUN git clone https://github.com/FelixKrueger/Bismark.git /msPIPE/bin/Bismark
RUN git clone https://github.com/BSSeeker/BSseeker2.git /msPIPE/bin/BSseeker2
RUN mkdir -p /msPIPE
COPY lib /msPIPE/lib
COPY bin /msPIPE/bin
COPY msPIPE.py /msPIPE/
ENV PATH=/msPIPE:$PATH:/usr/local/bin/
ENV R_LIBS_USER="/home/user/Rlibs"
RUN mkdir -p /work_dir

WORKDIR /work_dir

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*