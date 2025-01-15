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

use strict;
use warnings;
use utf8;

our $Self;

use Kernel::System::Encode;
use Kernel::System::GeneralCatalog;
use Kernel::System::ImportExport;
use Kernel::System::ImportExport::ObjectBackend::CustomerCompany;
use Kernel::System::CustomerCompany;
use Kernel::System::XML;

my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$Self->{CustomerCompanyObject} = Kernel::System::CustomerCompany->new( %{$Self} );
$Self->{EncodeObject}          = Kernel::System::Encode->new( %{$Self} );
$Self->{GeneralCatalogObject}  = Kernel::System::GeneralCatalog->new( %{$Self} );
$Self->{ImportExportObject}    = Kernel::System::ImportExport->new( %{$Self} );
$Self->{ObjectBackendObject}   = Kernel::System::ImportExport::ObjectBackend::CustomerCompany->new( %{$Self} );

# ------------------------------------------------------------ #
# make preparations
# ------------------------------------------------------------ #

# add some test templates for later checks
my @TemplateIDs;
for ( 1 .. 30 ) {

    # add a test template for later checks
    my $TemplateID = $Self->{ImportExportObject}->TemplateAdd(
        Object  => 'CustomerCompany',
        Format  => 'UnitTest' . $_,
        Name    => 'UnitTest' . $_,
        ValidID => 1,
        UserID  => 1,
    );

    push @TemplateIDs, $TemplateID;
}

my $TestCount = 1;

# ------------------------------------------------------------ #
# ObjectList test 1 (check CSV item)
# ------------------------------------------------------------ #

# get object list
my $ObjectList1 = $Self->{ImportExportObject}->ObjectList();

# check object list
$Self->True(
    $ObjectList1 && ref $ObjectList1 eq 'HASH' && $ObjectList1->{CustomerCompany},
    "Test $TestCount: ObjectList() - CustomerCompany exists",
);

$TestCount++;

# ------------------------------------------------------------ #
# ObjectAttributesGet test 1 (check attribute hash)
# ------------------------------------------------------------ #

#
#
# TO DO
#
#
