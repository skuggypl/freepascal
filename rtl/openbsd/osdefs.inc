{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2002 Marco van de Voort
    member of the Free Pascal development team.

    Target dependent defines used when compiling the baseunix unit
    Copied over to openbsd directory because of
    missing SigTimedWait syscall

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$define usedomain}             // Allow uname with "domain" entry.
                                // (which is a GNU extension)
{$define hassysctl}             // Use sysctl unit

{ SigTimedWait syscal does not seem to exist for OpenBSD OS }
{$define FPC_SYS_SIGTIMEDWAIT_UNAVAILABLE}
