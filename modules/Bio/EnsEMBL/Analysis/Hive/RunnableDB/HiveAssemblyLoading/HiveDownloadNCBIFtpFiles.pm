#!/usr/bin/env perl

# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveAssemblyLoading::HiveDownloadNCBIFtpFiles;

use strict;
use warnings;
use feature 'say';


use Bio::EnsEMBL::Utils::Exception qw(warning throw);
use parent ('Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveBaseRunnableDB');

sub fetch_input {
  my $self = shift;
  return 1;
  unless($self->param('ftp_species_path') && $self->param('local_path') && $self->param('primary_assembly_dir_name')) {
    throw("Must pass in the following parameters:\nftp_species_path e.g /genomes/genbank/vertebrate_mammalian/Canis_lupus/".
          "all_assembly_versions/GCA_000002285.2_CanFam3.1/GCA_000002285.2_CanFam3.1_assembly_structure/\n".
          "local_path e.g /path/to/work/dir\n".
          "primary_assembly_dir_name e.g. Primary_Assembly (usually this on NCBI ftp)");
  }

}

sub run {
  my $self = shift;

  my $ftp_species_path = $self->param('ftp_species_path');
  my $local_path = $self->param('local_path');
  my $primary_assembly_dir_name = $self->param('primary_assembly_dir_name');
  download_ftp_dir($ftp_species_path."/".$primary_assembly_dir_name,$local_path."/".$primary_assembly_dir_name);
  unzip($local_path."/".$primary_assembly_dir_name);

  say "Finished downloading NCBI ftp structure and files";
  return 1;
}

sub download_ftp_dir {
  my ($ftp_path,$local_dir) = @_;

  my $wget_verbose = "-nv";

  my @dirs = split(/\//,$ftp_path); # get array of names of subdirectories
  my @cleaned_dirs = map {$_ ? $_ : ()} @dirs; # delete empty elements in the array
  my $numDirs = @cleaned_dirs; # count the number of dirs we need to skip to be able to put the files in the local path specified as parameter

  if (system("wget --no-proxy ".$wget_verbose." -r -nH --cut-dirs=".$numDirs." --reject *.rm.out.gz -P ".$local_dir." ".$ftp_path)) {
      throw("could not download the AGP, FASTA and info files\n");
  }

  # check if no file was downloaded
  my $num_files = int(`find $local_dir -type f | wc -l`);
  if ($num_files == 0) {
    throw("No file was downloaded from ".$ftp_path." to ".$local_dir.". Please, check that both paths are valid.");
  } else {
    say "$num_files files were downloaded";
  }

  # get the name of the directory where the assembly report file is
  my @ftp_path_array = split('/',$ftp_path);
  my $ass_report_dir = pop(@ftp_path_array); # Primary assembly dir
  $ass_report_dir = pop(@ftp_path_array);
  $ass_report_dir = pop(@ftp_path_array);
  $ass_report_dir = pop(@ftp_path_array);

  my $link  = $ftp_path."/../../../".$ass_report_dir."_assembly_report.txt";
  say "FM2 ".$link;

  if (system("wget ".$wget_verbose." -nH -P ".$local_dir." ".$ftp_path."/../../../".$ass_report_dir."_assembly_report.txt -O ".$local_dir."/assembly_report.txt")) {
    throw("Could not download *_assembly_report.txt file from ".$ftp_path."/../../../ to ".$local_dir.". Please, check that both paths are valid.");
  }
  else {
    say "Assembly report file was downloaded";
  }
}

sub unzip {
  my ($path,) = @_;
  say "Unzipping the compressed files...";
  throw("gunzip operation failed. Please check your error log file.") if (system("gunzip -r $path") == 1);
  say "Unzipping finished!";
}

sub write_output {
  my $self = shift;

  return 1;
}

1;
