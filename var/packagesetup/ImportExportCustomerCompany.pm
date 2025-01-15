# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2012-2023 Znuny GmbH, http://znuny.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
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

package var::packagesetup::ImportExportCustomerCompany;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::ImportExport::ObjectBackend::CustomerCompany',
    'Kernel::System::ImportExport',
    'Kernel::System::CustomerUser',
    'Kernel::System::Log',
    'Kernel::Config'
);

=head1 NAME

var::packagesetup::ImportExportCustomerCompany - code to excecute during package installation

=head1 SYNOPSIS

All functions

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    use Kernel::Config;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::Time;
    use Kernel::System::DB;
    use Kernel::System::XML;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject    = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $XMLObject = Kernel::System::XML->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
    );
    my $CodeObject = var::packagesetup::OTRS-CiCS-ITSM.pm->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
        TimeObject   => $TimeObject,
        DBObject     => $DBObject,
        XMLObject    => $XMLObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    $Self->_CreateMappings();

    return 1;
}

=head2 CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    $Self->_CreateMappings();

    return 1;
}

=head2 CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    $Self->_RemoveRelatedMappings();

    return 1;
}

sub _RemoveRelatedMappings () {

    my ( $Self, %Param ) = @_;

    my $TemplateList = $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateList(
        Object => 'CustomerCompany',
        Format => 'CSV',
        UserID => 1,
    );

    if ( ref($TemplateList) eq 'ARRAY' && @{$TemplateList} ) {
        $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateDelete(
            TemplateID => $TemplateList,
            UserID     => 1,
        );
    }

    return 1;
}

sub _CreateMappings () {
    my ( $Self, %Param ) = @_;

    my $TemplateObject = "CustomerCompany";
    my $TemplateName   = "CustomerCompany (auto-created map)";
    my %TemplateList   = ();

    # get config option
    my $ForceCSVMappingConfiguration = $Kernel::OM->Get('Kernel::Config')->Get(
        'ImportExport::ImportExportCustomerCompany::ForceCSVMappingRecreation'
    ) || '0';

    #---------------------------------------------------------------------------
    # get list of all templates
    my $TemplateListRef = $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateList(
        Object => $TemplateObject,
        Format => 'CSV',
        UserID => 1,
    );

    # get data for each template and build hash with key = template name; value = template ID
    if ( $TemplateListRef && ref($TemplateListRef) eq 'ARRAY' ) {
        for my $CurrTemplateID ( @{$TemplateListRef} ) {
            my $TemplateDataRef = $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateGet(
                TemplateID => $CurrTemplateID,
                UserID     => 1,
            );
            if (
                $TemplateDataRef
                && ref($TemplateDataRef) eq 'HASH'
                && $TemplateDataRef->{Object}
                && $TemplateDataRef->{Name}
                )
            {
                $TemplateList{ $TemplateDataRef->{Object} . '::' . $TemplateDataRef->{Name} }
                    = $CurrTemplateID;
            }
        }
    }

    #---------------------------------------------------------------------------
    # add a template customer company
    my $TemplateID;

    # check if template already exists...
    if ( $TemplateList{ $TemplateObject . '::' . $TemplateName } ) {
        if ($ForceCSVMappingConfiguration) {

            # delete old template
            $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateDelete(
                TemplateID => $TemplateList{ $TemplateObject . '::' . $TemplateName },
                UserID     => 1,
            );
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message  => "CSV mapping deleted for re-creation <"
                    . $TemplateName
                    . ">.",
            );

            # create new template
            $TemplateID = $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateAdd(
                Object  => $TemplateObject,
                Format  => 'CSV',
                Name    => $TemplateName,
                Comment => "Automatically created during ImportExportCustomerCompany installation",
                ValidID => 1,
                UserID  => 1,
            );
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "CSV mapping already exists and not re-created <"
                    . $TemplateName
                    . ">.",
            );
            return 1;
        }
    }
    else {

        # create new template
        $TemplateID = $Kernel::OM->Get('Kernel::System::ImportExport')->TemplateAdd(
            Object  => $TemplateObject,
            Format  => 'CSV',
            Name    => $TemplateName,
            Comment => "Automatically created during ImportExportCustomerCompany installation",
            ValidID => 1,
            UserID  => 1,
        );
    }

    #---------------------------------------------------------------------------
    # mapping for customer company
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

    my $ExportDataSets = [
        {
            SourceExportData => {
                FormatData => {
                    ColumnSeparator      => 'Semicolon',
                    Charset              => 'UTF-8',
                    IncludeColumnHeaders => '1',
                },

                MappingObjectData => \@ElementList,
                ExportDataGet     => {
                    TemplateID => $TemplateID,
                    UserID     => 1,
                },
            },
        }
    ];

    #---------------------------------------------------------------------------
    # get object attributes
    my $ObjectAttributeList = $Kernel::OM->Get('Kernel::System::ImportExport')->ObjectAttributesGet(
        TemplateID => $ExportDataSets->[0]->{SourceExportData}->{ExportDataGet}->{TemplateID},
        UserID     => 1,
    );
    my $AttributeValues;
    for my $Default ( @{$ObjectAttributeList} ) {
        $AttributeValues->{ $Default->{Key} } = $Default->{Input}->{ValueDefault};
    }
    $ExportDataSets->[0]->{SourceExportData}->{ObjectData} = $AttributeValues;

    #---------------------------------------------------------------------------
    # run general ExportDataGet
    EXPORTDATASET:
    for my $CurrentExportDataSet ( @{$ExportDataSets} ) {

        # check SourceExportData attribute
        if (
            !$CurrentExportDataSet->{SourceExportData}
            || ref $CurrentExportDataSet->{SourceExportData} ne 'HASH'
            )
        {

            next EXPORTDATASET;
        }

        # set the object data
        if (
            $CurrentExportDataSet->{SourceExportData}->{ObjectData}
            && ref $CurrentExportDataSet->{SourceExportData}->{ObjectData} eq 'HASH'
            && $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID}
            )
        {

            # save object data
            $Kernel::OM->Get('Kernel::System::ImportExport')->ObjectDataSave(
                TemplateID =>
                    $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID},
                ObjectData => $CurrentExportDataSet->{SourceExportData}->{ObjectData},
                UserID     => 1,
            );
        }

        # set the format data
        if (
            $CurrentExportDataSet->{SourceExportData}->{FormatData}
            && ref $CurrentExportDataSet->{SourceExportData}->{FormatData} eq 'HASH'
            && $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID}
            )
        {

            # save format data
            $Kernel::OM->Get('Kernel::System::ImportExport')->FormatDataSave(
                TemplateID =>
                    $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID},
                FormatData => $CurrentExportDataSet->{SourceExportData}->{FormatData},
                UserID     => 1,
            );
        }

        # set the mapping object data
        if (
            $CurrentExportDataSet->{SourceExportData}->{MappingObjectData}
            && ref $CurrentExportDataSet->{SourceExportData}->{MappingObjectData} eq 'ARRAY'
            && $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID}
            )
        {

            # delete all existing mapping data
            $Kernel::OM->Get('Kernel::System::ImportExport')->MappingDelete(
                TemplateID =>
                    $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID},
                UserID => 1,
            );

            # add the mapping object rows
            MAPPINGOBJECTDATA:
            for my $MappingObjectData (
                @{ $CurrentExportDataSet->{SourceExportData}->{MappingObjectData} }
                )
            {

                # add a new mapping row
                my $MappingID = $Kernel::OM->Get('Kernel::System::ImportExport')->MappingAdd(
                    TemplateID =>
                        $CurrentExportDataSet->{SourceExportData}->{ExportDataGet}->{TemplateID},
                    UserID => 1,
                );

                # add the mapping object data
                $Kernel::OM->Get('Kernel::System::ImportExport')->MappingObjectDataSave(
                    MappingID         => $MappingID,
                    MappingObjectData => $MappingObjectData,
                    UserID            => 1,
                );
            }
        }

        # Export data save
        my $ConfigItemID =
            $Kernel::OM->Get('Kernel::System::ImportExport::ObjectBackend::CustomerCompany')
            ->ExportDataGet( %{ $CurrentExportDataSet->{SourceExportData}->{ExportDataGet} }, );

    }

    return 1;

}

1;
