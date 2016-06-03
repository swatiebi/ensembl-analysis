# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016] EMBL-European Bioinformatics Institute
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

=head1 NAME

Bio::EnsEMBL::Analysis::RunnableDB::Funcgen::Nessie

=head1 SYNOPSIS

  my $runnable = Bio::EnsEMBL::Analysis::RunnableDB::Funcgen::Nessie->new
     (
         -db       => $db,
         -input_id => 'chromosome::20:1:100000:1',
         -analysis => $analysis,
     );
  $runnable->fetch_input;
  $runnable->run;
  $runnable->write_output;

=head1 DESCRIPTION

This module provides an interface between the ensembl database and
the Runnable Nessie which wraps the program Nessie

=head1 AUTHOR

Stefan Graf, Ensembl Functional Genomics - http://www.ensembl.org/

=head1 CONTACT

Post questions to the Ensembl development list: http://lists.ensembl.org/mailman/listinfo/dev

=cut

package Bio::EnsEMBL::Analysis::RunnableDB::Funcgen::Nessie;

use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::Analysis::Config::General;
use Bio::EnsEMBL::Analysis::Config::Funcgen::Nessie;

use Bio::EnsEMBL::Analysis::RunnableDB;
use Bio::EnsEMBL::Analysis::RunnableDB::Funcgen;
use Bio::EnsEMBL::Analysis::Runnable::Funcgen::Nessie;

use Bio::EnsEMBL::Utils::Exception qw(throw warning stack_trace_dump);
use vars qw(@ISA); 

@ISA = qw(Bio::EnsEMBL::Analysis::RunnableDB::Funcgen);

=head2 new

  Arg [1]     : 
  Arg [2]     : 
  Description : Instantiates new Nessie runnabledb
  Returntype  : Bio::EnsEMBL::Analysis::RunnableDB::Funcgen::Nessie object
  Exceptions  : 
  Example     : 

=cut

sub new {

    print "Analysis::RunnableDB::Funcgen::Nessie::new\n";
    my ($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->read_and_check_config($CONFIG);

    # add some runnable/program special params to analysis
    $self->PARAMETERS(join('; ',
                           $self->PARAMETERS.$self->TRAIN_PARAMETERS,
                           $self->PEAK_PARAMETERS));
    #print Dumper $self->PARAMETERS;
    
    # make sure we have the correct analysis object
    $self->check_Analysis();

    # make sure we can store the correct feature_set, data_sets, and result_sets
    $self->check_Sets();

    return $self;

}

sub TRAIN_PARAMETERS {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        $self->{'_CONFIG_TRAIN_PARAMETERS'} = $value;
    }

    if ( exists( $self->{'_CONFIG_TRAIN_PARAMETERS'} ) ) {
        return $self->{'_CONFIG_TRAIN_PARAMETERS'};
    } else {
        return undef;
    }
}

sub PEAK_PARAMETERS {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        $self->{'_CONFIG_PEAK_PARAMETERS'} = $value;
    }

    if ( exists( $self->{'_CONFIG_PEAK_PARAMETERS'} ) ) {
        return $self->{'_CONFIG_PEAK_PARAMETERS'};
    } else {
        return undef;
    }
}




1;
