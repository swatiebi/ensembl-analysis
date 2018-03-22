#!/usr/bin/env perl

# Copyright [2016-2018] EMBL-European Bioinformatics Institute
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveDumpGenome;

use strict;
use warnings;
use feature 'say';

use File::Spec::Functions;
use File::Path qw(make_path);

use parent ('Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveBaseRunnableDB');

sub fetch_input {
  my $self = shift;

  unless($self->param('target_db')) {
    $self->throw("target_db not passed into parameters hash. The core db to load the assembly info ".
                 "into must be passed in with write access. You need to pass in the connection hash with 'target_db'");
  }

  unless($self->param('species_name')) {
    $self->throw("species_name not passed into parameters hash. You need to specify what species you're working on with 'species_name'");
  }

  if ($self->param('output_path')) {
    my $output_path = $self->param('output_path');
    if (!-e $output_path) {
      make_path($output_path);
      `lfs setstripe -c -1 $output_path`;
    }
  }
  else {
    $self->throw("Output path not passed into parameters hash. You need to specify where the output dir will be with 'output_path'");
  }

  unless($self->param('coord_system_name')) {
    $self->throw("Coord system name was not passed in using the 'coord_system_version' parameter");
  }

  unless($self->param('enscode_root_dir')) {
    $self->throw("enscode_dir not passed into parameters hash. You need to specify where your code checkout is");
  }

  return 1;
}

sub run {
  my $self = shift;

  my $db_info = $self->param('target_db');
  my $repeat_logic_names = $self->param('repeat_logic_names');
  my $repeat_string;
  if(scalar(@{$repeat_logic_names})) {
    $repeat_string .= ' -mask -softmask ';
    foreach my $repeat_logic_name (@{$repeat_logic_names}) {
      $repeat_string .= ' -mask_repeat '.$repeat_logic_name;
    }
  }

  my $cmd = 'perl '.catfile($self->param('enscode_root_dir'), 'ensembl-analysis', 'scripts', 'sequence_dump.pl').
            ' -dbuser '.$db_info->{-user}.
            ' -dbport '.$db_info->{-port}.
            ' -dbhost '.$db_info->{-host}.
            ' -dbname '.$db_info->{-dbname}.
            ' -coord_system_name '.$self->param('coord_system_name').
            ' -toplevel'.
            ' -onefile'.
            ' -nonref'.
            ' -filename '.catfile($self->param('output_path'), $self->param('species_name').'_softmasked_toplevel.fa');

  $cmd .= $repeat_string if ($repeat_string);
  $cmd .= ' -dbpass '.$db_info->{-pass} if ($db_info->{-pass});

  if($self->param('patch_only')) {
    $cmd .= " -patch_only ";
  }

  say "Running command:\n".$cmd;

  if (system($cmd)) {
    $self->throw("Command to dump the genome failed. Commandline used:\n".$cmd);
  }

  return 1;
}

sub write_output {
  my $self = shift;

  return 1;
}

1;
