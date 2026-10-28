# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2012-2023 Znuny GmbH, http://znuny.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::ImportExport::ObjectBackend::CustomerCompany;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::ImportExport',
    'Kernel::System::CustomerCompany',
    'Kernel::System::Log',
    'Kernel::Config',
    'Kernel::System::ReferenceData',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::ImportExport::ObjectBackend::CustomerCompany - import/export backend for CustomerUser

=head1 SYNOPSIS

All functions to import and export CustomerCompany entries

=head2 new()

create an object

    use Kernel::Config;
    use Kernel::System::DB;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::ImportExport::ObjectBackend::CustomerCompany;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $BackendObject = Kernel::System::ImportExport::ObjectBackend::CustomerCompany->new(
        ConfigObject       => $ConfigObject,
        LogObject          => $LogObject,
        DBObject           => $DBObject,
        MainObject         => $MainObject,
        ImportExportObject => $ImportExportObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ObjectAttributesGet()

get the object attributes of an object as array/hash reference

    my $Attributes = $ObjectBackend->ObjectAttributesGet(
        UserID => 1,
    );

=cut

sub ObjectAttributesGet {
    my ( $Self, %Param ) = @_;

    # check needed object
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log(
                Priority => 'error',
                Message  => 'Need UserID!'
            );
        return;
    }

    my %Validlist = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

    my $Attributes = [
        {
            Key   => 'DefaultValid',
            Name  => 'Default Validity',
            Input => {
                Type         => 'Selection',
                Data         => \%Validlist,
                Required     => 1,
                Translation  => 1,
                PossibleNone => 0,
                ValueDefault => 1,
            },
        },
    ];

    return $Attributes;
}

=head2 MappingObjectAttributesGet()

get the mapping attributes of an object as array/hash reference

    my $Attributes = $ObjectBackend->MappingObjectAttributesGet(
        TemplateID => 123,
        UserID     => 1,
    );

=cut

sub MappingObjectAttributesGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get object data
    my $ObjectData = $Kernel::OM->Get('Kernel::System::ImportExport')->ObjectDataGet(
        TemplateID => $Param{TemplateID},
        UserID     => $Param{UserID},
    );

    my @ElementList = qw{};
    $Self->{CustomerCompanyKey}
        = $Kernel::OM->Get('Kernel::Config')->Get('CustomerCompany')->{CustomerCompanyKey}
        || $Kernel::OM->Get('Kernel::Config')->Get('CustomerCompany')->{Key}
        || die "Need CustomerCompany->CustomerCompanyKey in Kernel/Config.pm!";
    $Self->{CustomerCompanyMap} = $Kernel::OM->Get('Kernel::Config')->Get('CustomerCompany')->{Map}
        || die "Need CustomerCompany->Map in Kernel/Config.pm!";

    for my $CurrAttributeMapping ( @{ $Self->{CustomerCompanyMap} } ) {
        my $CurrAttribute = {
            Key   => $CurrAttributeMapping->[0],
            Value => $CurrAttributeMapping->[0],
        };

        # if ValidID is available - offer Valid instead..
        if ( $CurrAttributeMapping->[0] eq 'ValidID' ) {
            $CurrAttribute = {
                Key   => 'Valid',
                Value => 'Validity',
            };
        }

        push( @ElementList, $CurrAttribute );

    }

    my $Attributes = [
        {
            Key   => 'Key',
            Name  => 'Key',
            Input => {
                Type         => 'Selection',
                Data         => \@ElementList,
                Required     => 1,
                Translation  => 0,
                PossibleNone => 1,
            },
        },

        # It doesn't make sense to configure and set the identifier:
        # CustomerID is used to search for existing enrties anyway!
        # (See sub ImportDataSave)
        #        {
        #            Key   => 'Identifier',
        #            Name  => 'Identifier',
        #            Input => { Type => 'Checkbox', },
        #        },
    ];

    return $Attributes;
}

=head2 SearchAttributesGet()

get the search object attributes of an object as array/hash reference

    my $AttributeList = $ObjectBackend->SearchAttributesGet(
        TemplateID => 123,
        UserID     => 1,
    );

=cut

sub SearchAttributesGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get object data
    my $ObjectData = $Kernel::OM->Get('Kernel::System::ImportExport')->ObjectDataGet(
        TemplateID => $Param{TemplateID},
        UserID     => $Param{UserID},
    );

    return;
}

=head2 ExportDataGet()

get export data as two-dimensional array-hash reference

    my $ExportData = $ObjectBackend->ExportDataGet(
        TemplateID => 123,
        UserID     => 1,
    );

=cut

sub ExportDataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get object data
    my $ObjectData = $Kernel::OM->Get('Kernel::System::ImportExport')->ObjectDataGet(
        TemplateID => $Param{TemplateID},
        UserID     => $Param{UserID},
    );

    # check object data
    if ( !$ObjectData || ref $ObjectData ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No object data found for the template id $Param{TemplateID}",
        );
        return;
    }

    # get the mapping list
    my $MappingList = $Kernel::OM->Get('Kernel::System::ImportExport')->MappingList(
        TemplateID => $Param{TemplateID},
        UserID     => $Param{UserID},
    );

    # check the mapping list
    if ( !$MappingList || ref $MappingList ne 'ARRAY' || !@{$MappingList} ) {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No valid mapping list found for the template id $Param{TemplateID}",
        );
        return;
    }

    # create the mapping object list
    my @MappingObjectList;
    for my $MappingID ( @{$MappingList} ) {

        # get mapping object data
        my $MappingObjectData =
            $Kernel::OM->Get('Kernel::System::ImportExport')->MappingObjectDataGet(
                MappingID => $MappingID,
                UserID    => $Param{UserID},
            );

        # check mapping object data
        if ( !$MappingObjectData || ref $MappingObjectData ne 'HASH' ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No valid mapping list found for the template id $Param{TemplateID}",
            );
            return;
        }

        push( @MappingObjectList, $MappingObjectData );
    }

    # list customer companys...
    my %CustomerCompanyList
        = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyList();

    my @ExportData;

    for my $CurrCompany ( keys %CustomerCompanyList ) {

        my %CustomerCompanyData =
            $Kernel::OM->Get('Kernel::System::CustomerCompany')
            ->CustomerCompanyGet( CustomerID => $CurrCompany );

        if (%CustomerCompanyData) {
            my @CurrRow;

            # prepare validity...
            if ( $CustomerCompanyData{ValidID} ) {
                $CustomerCompanyData{Valid}
                    = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
                        ValidID => $CustomerCompanyData{ValidID},
                    );
            }

            for my $MappingObject (@MappingObjectList) {
                my $Key = $MappingObject->{Key};
                if ( !$Key ) {
                    push @CurrRow, '';
                }
                else {
                    push( @CurrRow, $CustomerCompanyData{$Key} || '' );
                }
            }
            push @ExportData, \@CurrRow;
        }

    }

    return \@ExportData;
}

=head2 ImportDataSave()

import one row of the import data

    my $ConfigItemID = $ObjectBackend->ImportDataSave(
        TemplateID    => 123,
        ImportDataRow => $ArrayReConfigf,
        UserID        => 1,
    );

=cut

sub ImportDataSave {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID ImportDataRow UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return ( undef, 'Failed' );
        }
    }

    # check import data row
    if ( ref $Param{ImportDataRow} ne 'ARRAY' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ImportDataRow must be an array reference',
        );
        return ( undef, 'Failed' );
    }

    # get object data
    my $ObjectData = $Kernel::OM->Get('Kernel::System::ImportExport')->ObjectDataGet(
        TemplateID => $Param{TemplateID},
        UserID     => $Param{UserID},
    );

    # check object data
    if ( !$ObjectData || ref $ObjectData ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No object data found for the template id $Param{TemplateID}",
        );
        return ( undef, 'Failed' );
    }

    # get the mapping list
    my $MappingList = $Kernel::OM->Get('Kernel::System::ImportExport')->MappingList(
        TemplateID => $Param{TemplateID},
        UserID     => $Param{UserID},
    );

    # check the mapping list
    if ( !$MappingList || ref $MappingList ne 'ARRAY' || !@{$MappingList} ) {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No valid mapping list found for the template id $Param{TemplateID}",
        );
        return ( undef, 'Failed' );
    }

    # create the mapping object list
    #    my @MappingObjectList;
    #    my %Identifier;
    #    my $CustomerCompanyKey     = "";

    my $Counter                = 0;
    my %NewCustomerCompanyData = qw{};

    #BUILD MAPPING TABLE...
    my $IsHeadline = 1;
    for my $MappingID ( @{$MappingList} ) {

        # get mapping object data
        my $MappingObjectData =
            $Kernel::OM->Get('Kernel::System::ImportExport')->MappingObjectDataGet(
                MappingID => $MappingID,
                UserID    => $Param{UserID},
            );

        # check mapping object data
        if ( !$MappingObjectData || ref $MappingObjectData ne 'HASH' ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No valid mapping list found for template id $Param{TemplateID}",
            );
            return ( undef, 'Failed' );
        }

        #        push( @MappingObjectList, $MappingObjectData );

        # TO DO: It doesn't make sense to configure and set the identifier:
        # CustomerID is used to search for existing enrties anyway!
        #
        #  See lines 529-530:
        #  my %CustomerCompanyData = $Self->{CustomerCompanyObject}
        #        ->CustomerCompanyGet( CustomerID => $NewCustomerCompanyData{CustomerID} );

        #        if (
        #            $MappingObjectData->{Identifier}
        #            && $Identifier{ $MappingObjectData->{Key} }
        #            )
        #        {
        #            $Self->{LogObject}->Log(
        #                Priority => 'error',
        #                Message  => "Can't import this entity. "
        #                    . "'$MappingObjectData->{Key}' has been used multiple "
        #                    . "times as identifier (line $Param{Counter}).!",
        #            );
        #        }
        #        elsif ( $MappingObjectData->{Identifier} ) {
        #            $Identifier{ $MappingObjectData->{Key} } =
        #                $Param{ImportDataRow}->[$Counter];
        #            $CustomerCompanyKey = $MappingObjectData->{Key};
        #        }

        if ( $MappingObjectData->{Key} ne "CustomerCompanyCountry" ) {
            $NewCustomerCompanyData{ $MappingObjectData->{Key} } =
                $Param{ImportDataRow}->[$Counter];
        }
        else {
            # Sanitize country if it isn't found in OTRS to increase the chance it will
            # Note that standardizing against the ISO 3166-1 list might be a better approach...
            my $CountryList = $Kernel::OM->Get('Kernel::System::ReferenceData')->CountryList();
            if ( exists $CountryList->{ $Param{ImportDataRow}->[$Counter] } ) {
                $NewCustomerCompanyData{ $MappingObjectData->{Key} }
                    = $Param{ImportDataRow}->[$Counter];
            }
            else {
                $NewCustomerCompanyData{ $MappingObjectData->{Key} } =
                    join( '', map { ucfirst lc } split /(\s+)/, $Param{ImportDataRow}->[$Counter] );
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'notice',
                    Message  => "Country '$Param{ImportDataRow}->[$Counter]' "
                        . "not found - save as '$NewCustomerCompanyData{ $MappingObjectData->{Key} }'.",
                );
            }
        }
        $Counter++;

    }

    #DO THE IMPORT...

    #(1) Preprocess data...

    # lookup Valid-ID...
    if ( !$NewCustomerCompanyData{ValidID} && $NewCustomerCompanyData{Valid} ) {
        $NewCustomerCompanyData{ValidID} = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
            Valid => $NewCustomerCompanyData{Valid}
        );
    }
    if ( !$NewCustomerCompanyData{ValidID} ) {
        $NewCustomerCompanyData{ValidID} = $ObjectData->{DefaultValid} || 1;
    }

    #(1) lookup company entry...
    my %CustomerCompanyData = $Kernel::OM->Get('Kernel::System::CustomerCompany')
        ->CustomerCompanyGet( CustomerID => $NewCustomerCompanyData{CustomerID} );

    my $NewCompany = 1;
    if (%CustomerCompanyData) {
        $NewCompany = 0;
    }

    KEY:
    for my $Key ( keys(%NewCustomerCompanyData) ) {
        next KEY if ( !$NewCustomerCompanyData{$Key} );
        $CustomerCompanyData{$Key} = $NewCustomerCompanyData{$Key};
    }

    #(2) if company DOES NOT exist => create new entry...
    my $Result     = 0;
    my $ReturnCode = "";    # Created | Changed | Failed

    if ($NewCompany) {
        $Result = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyAdd(
            %CustomerCompanyData,
            UserID => $Param{UserID},
        );

        if ( !$Result ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "ImportDataSave: adding CustomerCompany ("
                    . "CustomerID "
                    . $CustomerCompanyData{CustomerID}
                    . ") failed (line $Param{Counter}).",
            );
        }
        else {
            $ReturnCode = "Created";
        }
    }

    #(3) if company DOES exist => check update...
    else {
        $Result = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyUpdate(
            %CustomerCompanyData,
            UserID => $Param{UserID},
        );

        if ( !$Result ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "ImportDataSave: updating CustomerCompany ("
                    . "CustomerID "
                    . $CustomerCompanyData{CustomerID}
                    . ") failed (line $Param{Counter}).",
            );
        }
        else {
            $ReturnCode = "Changed";
        }
    }

    #

    return ( $Result, $ReturnCode );
}

1;
