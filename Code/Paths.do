*================== Set working path ========================================

// 1: Ricardo Laptop
// 2: Ricardo Office
// 3: Sofia Laptop



if ("`c(username)'"  == "ricar") {
global hp = "C:\Users\ricar\Dropbox\Multipliers\EMU_Austerity\"
cd "C:\Users\ricar\Dropbox\Multipliers\EMU_Austerity\Code\"
}

if ("`c(username)'"  == "user") {
global hp = "C:\Users\user\Dropbox\Multipliers\EMU_Austerity\"
cd "C:\Users\user\Dropbox\Multipliers\EMU_Austerity\Code\"
}

if ("`c(username)'"  == "sofia") {
global hp = "C:\Users\Sofia\Dropbox\EMU_Austerity\"
*cd "C:\Users\Sofia\Dropbox\EMU_Austerity\Code\"
}

global Fig = "$hp\Outputs\Figures\"
global Tab = "$hp\Outputs\Tables\"
global Descriptives = "$hp\Outputs\Figures\"

