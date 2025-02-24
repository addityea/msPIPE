FROM ubuntu:noble

LABEL description="methyl-data analysis pipeline"
ENV TZ=Europe/Stockholm
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
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
      build-essential software-properties-common \
      libcurl4-openssl-dev \
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
      bedops

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

RUN R -e "install.packages('BiocManager', repos='http://cran.rstudio.com/')"
RUN R -e "BiocManager::install('BiocGenerics')"
RUN R -e "BiocManager::install('S4Vectors')"
RUN R -e "BiocManager::install('rhtslib')"
RUN R -e "BiocManager::install('IRanges')"
RUN R -e "BiocManager::install('GenomeInfoDb')"
RUN R -e "BiocManager::install('GenomicRanges')"
RUN R -e "BiocManager::install('Biostrings')"
RUN R -e "BiocManager::install('rtracklayer')"
RUN R -e "BiocManager::install('BSgenome')"
RUN R -e "BiocManager::install('methylKit')"
RUN R -e "BiocManager::install('methylSeekR')"
RUN R -e "BiocManager::install('bsseq')"
RUN R -e "BiocManager::install('BiocParallel')"

RUN R -e "install.packages('circlize', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('MASS', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('stringi', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ggplot2', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('gprofiler2', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('doParallel', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('foreach', repos='http://cran.rstudio.com/')"

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
# Add /usr/local/bin/ to PATH
RUN echo 'export PATH=$PATH:/usr/local/bin/' >> /etc/bash.bashrc
RUN mkdir -p /work_dir

WORKDIR /work_dir

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*