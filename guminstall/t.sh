nc="\e[0m"
red="\e[31m"
cyan="\e[36m"
blue="\e[94m"
green="\e[32m"
redl="\e[1;31m"
yellow="\e[33m"
cyanl="\e[1;36m"
redbg="\e[1;41m"
magenta="\e[35m"
bwhite="\e[0;97m"
cyanbg="\e[1;46m"
bluebg="\e[1;44m"
greenl="\e[1;32m"
greenbg="\e[1;42m"
yellowl="\e[1;33m"
magental="\e[1;35m"
magentabg="\e[1;45m"
MAGENTABG() { echo -e "${magentabg} $1${nc}" ;}
YELLOWL()   { echo -e "${yellowl} $1${nc}"   ;}
GREENBG()   { echo -e "${greenbg} $1${nc}"   ;}
MAGENTA()   { echo -e "${magenta} $1${nc}"   ;}
YELLOW()    { echo -e "${yellow} $1${nc}"    ;}
BLUEBG()    { echo -e "${bluebg} $1${nc}"    ;}
CYANBG()    { echo -e "${cyanbg} $1${nc}"    ;}
WHITEB()    { echo -e "${bwhite} $1${nc}"    ;}
GREEN()     { echo -e "${green} $1${nc}"     ;}
REDBG()     { echo -e "${redbg} $1${nc}"     ;}
BLUE()      { echo -e "${blue} $1${nc}"      ;}
CYAN()      { echo -e "${cyan} $1${nc}"      ;}
RED()       { echo -e "${red} $1${nc}"       ;}
NC()        { echo -e "${nc} $1${nc}"        ;}


sanity_check() {

        sleep 0.2
        NC "

${magenta}###${nc}--------------------------------------${magenta}[ ${bwhite}Sanity  Check${nc} ${magenta}]${nc}--------------------------------------${magenta}###
        "
        rootcount="$(fdisk -l "${instl_drive}" | grep -E -c 'root' | awk "{print \$1}")"
        root_dev="$(fdisk -l "${instl_drive}" | grep -E 'root' | awk "{print \$1}")"
        multi_root="$(fdisk -l "${instl_drive}" | grep -E 'root' | awk "{print \$1}" | cat --number)"
        root_comply="$(fdisk -l "${instl_drive}" | grep -E 'root' | awk "{print \$1}" | cat --number | grep -E '1[[:blank:]]' | awk "{print \$2}")"
        espcount="$(fdisk -l "${instl_drive}" | grep -E -c 'EFI' | awk "{print \$1}")"
        esp_dev="$(fdisk -l "${instl_drive}" | grep -E 'EFI' | awk "{print \$1}")"
        multi_esp="$(fdisk -l "${instl_drive}" | grep -E 'EFI' | awk "{print \$1}" | cat --number)"
        esp_comply="$(fdisk -l "${instl_drive}" | grep -E 'EFI' | awk "{print \$1}" | cat --number | grep -E '1[[:blank:]]' | awk "{print \$2}")"
        xbootcount="$(fdisk -l "${instl_drive}" | grep -E -c 'extended' | awk "{print \$1}")"
        xboot_dev="$(fdisk -l "${instl_drive}" | grep -E 'extended' | awk "{print \$1}")"
        multi_xboot="$(fdisk -l "${instl_drive}" | grep -E 'extended' | awk "{print \$1}" | cat --number)"
        xboot_comply="$(fdisk -l "${instl_drive}" | grep -E 'extended' | awk "{print \$1}" | cat --number | grep -E '1[[:blank:]]' | awk "{print \$2}")"
        homecount="$(fdisk -l "${instl_drive}" | grep -E -c 'home' | awk "{print \$1}")"
        home_dev="$(fdisk -l "${instl_drive}" | grep -E 'home' | awk "{print \$1}")"
        multi_home="$(fdisk -l "${instl_drive}" | grep -E 'home' | awk "{print \$1}" | cat --number)"
        home_comply="$(fdisk -l "${instl_drive}" | grep -E 'home' | awk "{print \$1}" | cat --number | grep -E '1[[:blank:]]' | awk "{print \$2}")"
        swapcount="$(fdisk -l "${instl_drive}" | grep -E -c 'swap' | awk "{print \$1}")"
        swap_dev="$(fdisk -l "${instl_drive}" | grep -E 'swap' | awk "{print \$1}")"
        multi_swap="$(fdisk -l "${instl_drive}" | grep -E 'swap' | awk "{print \$1}" | cat --number)"
        swap_comply="$(fdisk -l "${instl_drive}" | grep -E 'swap' | awk "{print \$1}" | cat --number | grep -E '1[[:blank:]]' | awk "{print \$2}")"

    if [[ "${rootcount}" -gt "1" ]]; then
        local stage_prompt="Selecting Partition"
        sleep 0.2
        CYAN "
        >>  ${nc}Multiple ${greenl}Linux x86-64 /Root ${nc}Partitions have been detected
        "
        sleep 0.2
        CYAN "
###${nc}------------------------------------------------${cyan}[ ${bwhite}DISK OVERVIEW ${nc}${cyan}]${nc}------------------------------------------------${cyan}###

        "
        fdisk -l "${instl_drive}" | grep -E --color=no 'Dev|dev' |GREP_COLORS='mt=01;36' grep -E --color=always 'EFI System|$'|GREP_COLORS='mt=01;32' grep -E --color=always 'Linux root|$'|GREP_COLORS='mt=01;35' grep -E --color=always 'Linux home|$'|GREP_COLORS='mt=01;33' grep -E --color=always 'Linux swap|$'|GREP_COLORS='mt=01;31' grep -E --color=always 'Linux extended boot|$'
        CYAN "

###${nc}-----------------------------------------------------------------------------------------------------------------${cyan}### "
        NC "
     ${greenl}Linux x86-64 /Root Partitions:${nc}
     
     ------------------------------
${multi_root}
     ------------------------------
        "
        YELLOW "

        ###  Only the 1st Linux x86-64 /Root partition on a selected disk can be auto-assigned as a valid /Root partition


        ###  Partition ${nc}${root_comply} ${yellow}is auto-assigned as such and will be ${red}[!] ${nc}FORMATTED ${red}[!]
                "
        BLUE "


        >  Proceed ? [Y/n]"
        read -r -p "
==> " autoroot

        autoroot="${autoroot:-y}"
        autoroot="${autoroot,,}"

        if [[ "${autoroot}" == "y" ]]; then
            root_dev="${root_comply}"
            multiroot_bootopts="root=PARTUUID=$(blkid -s PARTUUID -o value "${root_dev}")"
        elif [[ "${autoroot}" == "n" ]]; then
            until auto_part; do : ; done
            return 0
        else
            y_n
            return 1
        fi
    fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if [[ "${espcount}" -gt "1" ]]; then
        local stage_prompt="Selecting Partition"
        sleep 0.2
        CYAN "
        >>  ${nc}Multiple ${cyanl}EFI System ${nc}Partitions have been detected
        "
        sleep 0.2
        CYAN "
###${nc}------------------------------------------------${cyan}[ ${bwhite}DISK OVERVIEW ${nc}${cyan}]${nc}------------------------------------------------${cyan}###

        "
        fdisk -l "${instl_drive}" | grep -E --color=no 'Dev|dev' |GREP_COLORS='mt=01;36' grep -E --color=always 'EFI System|$'|GREP_COLORS='mt=01;32' grep -E --color=always 'Linux root|$'|GREP_COLORS='mt=01;35' grep -E --color=always 'Linux home|$'|GREP_COLORS='mt=01;33' grep -E --color=always 'Linux swap|$'|GREP_COLORS='mt=01;31' grep -E --color=always 'Linux extended boot|$'
        CYAN "

###${nc}-----------------------------------------------------------------------------------------------------------------${cyan}### "
        NC "
     ${cyanl}Linux EFI System Partitions:${nc}
     
     ----------------------------
${multi_esp}
     ----------------------------
        "
        YELLOW "

        ###  Only the 1st EFI partition on a selected disk can be auto-assigned as a valid EFI partition
        "
        if [[ "${multibooting}" == "n" ]]; then
            YELLOW "
        ###  Partition ${nc}${esp_comply} ${yellow}is auto-assigned as such and will be ${red}[!] ${nc}FORMATTED ${red}[!]
            "
        elif [[ "${multibooting}" == "y" ]]; then
            YELLOW "
        ###  Partition ${nc}${esp_comply} ${yellow}is auto-assigned as such
            "
        fi
        BLUE "


        >  Proceed ? [Y/n]"
        read -r -p "
==> " autoesp

        autoesp="${autoesp:-y}"
        autoesp="${autoesp,,}"

        if [[ "${autoesp}" == "y" ]]; then
            esp_dev="${esp_comply}"
        elif [[ "${autoesp}" == "n" ]]; then
            until auto_part; do : ; done
            return 0
        else
            y_n
            return 1
        fi
    fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if [[ "${xbootcount}" -gt "1" ]]; then
        local stage_prompt="Selecting Partition"
        sleep 0.2
        CYAN "
        >>  ${nc}Multiple ${redl}Linux Extended Boot ${nc}Partitions have been detected
        "
        sleep 0.2
        CYAN "
###${nc}------------------------------------------------${cyan}[ ${bwhite}DISK OVERVIEW ${nc}${cyan}]${nc}------------------------------------------------${cyan}###

        "
        fdisk -l "${instl_drive}" | grep -E --color=no 'Dev|dev' |GREP_COLORS='mt=01;36' grep -E --color=always 'EFI System|$'|GREP_COLORS='mt=01;32' grep -E --color=always 'Linux root|$'|GREP_COLORS='mt=01;35' grep -E --color=always 'Linux home|$'|GREP_COLORS='mt=01;33' grep -E --color=always 'Linux swap|$'|GREP_COLORS='mt=01;31' grep -E --color=always 'Linux extended boot|$'
        CYAN "

###${nc}-----------------------------------------------------------------------------------------------------------------${cyan}### "
        NC "
     ${redl}Linux Extended Boot Partitions:${nc}
     
     ----------------------------
${multi_xboot}
     ----------------------------
        "
        YELLOW "

        ###  Only the 1st Linux Extended Boot partition on a selected disk can be auto-assigned as a valid XBOOTLDR partition


        ###  Partition ${nc}${xboot_comply} ${yellow}is auto-assigned as such and will be ${red}[!] ${nc}FORMATTED ${red}[!]
                "
        BLUE "


        >  Proceed ? [Y/n]"
        read -r -p "
==> " autoxboot

        autoxboot="${autoxboot:-y}"
        autoxboot="${autoxboot,,}"

        if [[ "${autoxboot}" == "y" ]]; then
            xboot_dev="${xboot_comply}"
        elif [[ "${autoxboot}" == "n" ]]; then
             until auto_part; do : ; done
            return 0
        else
            y_n
            return 1
        fi
    fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if [[ "${fs}" == "1" && "${sep_home}" == "y" && "${homecount}" -gt "1" ]]; then
        local stage_prompt="Selecting Partition"
        sleep 0.2
        CYAN "
        >>  ${nc}Multiple ${magental}Linux /Home ${nc}Partitions have been detected
        "
        sleep 0.2
        CYAN "
###${nc}------------------------------------------------${cyan}[ ${bwhite}DISK OVERVIEW ${nc}${cyan}]${nc}------------------------------------------------${cyan}###

        "
        fdisk -l "${instl_drive}" | grep -E --color=no 'Dev|dev' |GREP_COLORS='mt=01;36' grep -E --color=always 'EFI System|$'|GREP_COLORS='mt=01;32' grep -E --color=always 'Linux root|$'|GREP_COLORS='mt=01;35' grep -E --color=always 'Linux home|$'|GREP_COLORS='mt=01;33' grep -E --color=always 'Linux swap|$'|GREP_COLORS='mt=01;31' grep -E --color=always 'Linux extended boot|$'
        CYAN "

###${nc}-----------------------------------------------------------------------------------------------------------------${cyan}### "
        NC "
     ${magental}Linux /Home Partitions:${nc}
     
     -----------------------
${multi_home}
     -----------------------
        "
        YELLOW "

        ###  Only the 1st Linux /Home partition on a selected disk can be auto-assigned as a valid /Home partition


        ###  Partition ${nc}${home_comply} ${yellow}is auto-assigned as such and will be ${red}[!] ${nc}FORMATTED ${red}[!]
        "
        BLUE "


        >  Proceed ? [Y/n]"
        read -r -p "
==> " autohome

        autohome="${autohome:-y}"
        autohome="${autohome,,}"

        if [[ "${autohome}" == "y" ]]; then
            home_dev="${home_comply}"
        elif [[ "${autohome}" == "n" ]]; then
            until auto_part; do : ; done
            return 0
        else
            y_n
            return 1
        fi
    fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if [[ "${swapmode}" == "1" && "${swapcount}" -gt "1" ]]; then
        local stage_prompt="Selecting Partition"
        sleep 0.2
        CYAN "
        >>  ${nc}Multiple ${yellowl}Linux /Swap ${nc}Partitions have been detected
        "
        sleep 0.2
        CYAN "
###${nc}------------------------------------------------${cyan}[ ${bwhite}DISK OVERVIEW ${nc}${cyan}]${nc}------------------------------------------------${cyan}###

        "
        fdisk -l "${instl_drive}" | grep -E --color=no 'Dev|dev' |GREP_COLORS='mt=01;36' grep -E --color=always 'EFI System|$'|GREP_COLORS='mt=01;32' grep -E --color=always 'Linux root|$'|GREP_COLORS='mt=01;35' grep -E --color=always 'Linux home|$'|GREP_COLORS='mt=01;33' grep -E --color=always 'Linux swap|$'|GREP_COLORS='mt=01;31' grep -E --color=always 'Linux extended boot|$'
        CYAN "

###${nc}-----------------------------------------------------------------------------------------------------------------${cyan}### "
        NC "
      ${yellowl}Linux /Swap Partitions:${nc}

     ------------------------
${multi_swap}
     ------------------------
        "
        YELLOW "

        ###  Only the 1st Linux /Swap partition on a selected disk can be auto-assigned as a valid /Swap partition


        ###  Partition ${nc}${swap_comply} ${yellow}is auto-assigned as such and will be ${red}[!] ${nc}FORMATTED ${red}[!]
                "
        BLUE "


        >  Proceed ? [Y/n]"
        read -r -p "
==> " autoswap

        autoswap="${autoswap:-y}"
        autoswap="${autoswap,,}"

        if [[ "${autoswap}" == "y" ]]; then
            swap_dev="${swap_comply}"
        elif [[ "${autoswap}" == "n" ]]; then
            until auto_part; do : ; done
            return 0
        else
            y_n
            return 1
        fi
    fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if [[ -e "${root_dev}" ]]; then
        rootpartsize="$(lsblk -dno SIZE --bytes "${root_dev}")"
        if [[ "${rootpartsize}" -ge "8589934592" ]]; then
            rootprt="ok"
        else
            rootprt="ok"
            sleep 0.2
            RED "
        -----------------------------------------------------
        ###  ${yellow}WARNING: ${nc}/Root's size might not be adequate  ${red}###
        -----------------------------------------------------"
            sleep 0.2
            RED "
        ------------------------------------------------------------------------
        ###  ${nc}Depending on the size of your setup, installation might fail !  ${red}###
        ------------------------------------------------------------------------"
            NC "



                                     ${bwhite}Press any key to continue${nc}


            "
            read -r -s -n 1
        fi
        if [[ "${autoroot}" == "y" ]]; then
            if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                sleep 0.2
                NC "

==> [Linux x86-64 /Root ${green}OK${nc}] "
            else
                local prompt="Confirmed /Root Partition"
                ok
            fi
        else
            sleep 0.2
            NC "

==> [Linux x86-64 /Root ${green}OK${nc}] "
        fi
    else
        rootprt="fail"
        sleep 0.2
        RED "
        ---------------------------------------------------
        ###  ${yellowl}Linux x86-64 /Root ${nc}Partition not detected  ${red}###
        ---------------------------------------------------"
    fi
#..................................................................................................

    if [[ ! -e "${esp_dev}" ]]; then
        espprt="fail"
        sleep 0.2
        RED "
        -------------------------------------------
        ###  ${yellowl}EFI System ${nc}Partition not detected  ${red}###
        -------------------------------------------"
    fi

    if [[ -e "${esp_dev}" ]]; then
        espsize="$(lsblk -dno SIZE --bytes "${esp_dev}")"
    fi

    if [[ "${espsize}" -ge "209715200" ]]; then
        espprt="ok"
        xbootloader="no"
        if [[ "${autoesp}" == "y" ]]; then
            if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                sleep 0.2
                NC "

==> [EFI System Partition ${green}OK${nc}] "
            else
                local prompt="Confirmed /EFI System Partition"
                ok
            fi
        else
            sleep 0.2
            NC "

==> [EFI System Partition ${green}OK${nc}] "
        fi
    fi

    if [[ -e "${esp_dev}" && "${espsize}" -lt "209715200" ]]; then
        if [[ "${bootloader}" == "1" ]]; then
            if [[ "${multibooting}" == "y" ]]; then
                xbootloader="yes"
                if [[ -e "${xboot_dev}" ]]; then
                    xbootprt="ok"
                    espprt="ok"
                    if [[ "${autoesp}" == "y" ]]; then
                        if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                            sleep 0.2
                            NC "

==> [EFI System Partition ${green}OK${nc}] "
                        else
                            local prompt="Confirmed /EFI System Partition"
                            ok
                        fi
                    else
                        sleep 0.2
                        NC "

==> [EFI System Partition ${green}OK${nc}] "
                    fi
                    if [[ "${autoxboot}" == "y" ]]; then
                        if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                            sleep 0.2
                            NC "

==> [Linux Extended Boot Partition ${green}OK${nc}] "
                        else
                            local prompt="Confirmed /XBOOTLDR Partition"
                            ok
                        fi
                    else
                        sleep 0.2
                        NC "

==> [Linux Extended Boot Partition ${green}OK${nc}] "
                    fi
                else
                    xbootprt="fail"
                    espprt="fail"
                    sleep 0.2
                    RED "
        ---------------------------------------------
        ###  ${yellow}WARNING: ${nc}ESP's size is not adequate  ${red}###
        ---------------------------------------------"
                    sleep 0.2
                    RED "
        ----------------------------------------------------
        ###  ${yellowl}Linux Extended Boot ${nc}Partition not detected  ${red}###
        ----------------------------------------------------"
                fi
            elif [[ "${multibooting}" == "n" ]]; then
                espprt="fail"
                xbootloader="no"
                sleep 0.2
                RED "
        ---------------------------------------------
        ###  ${yellow}WARNING: ${nc}ESP's size is not adequate  ${red}###
        ---------------------------------------------"
            fi
        elif [[ "${bootloader}" == "2" ]]; then
            if [[ "${espmnt}" == "2" ]]; then
                espprt="fail"
                xbootloader="no"
                sleep 0.2
                RED "
        ---------------------------------------------
        ###  ${yellow}WARNING: ${nc}ESP's size is not adequate  ${red}###
        ---------------------------------------------"
            elif [[ "${espmnt}" == "1" ]]; then
                espprt="ok"
                xbootloader="no"
                if [[ "${autoesp}" == "y" ]]; then
                    if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                        sleep 0.2
                        NC "

==> [EFI System Partition ${green}OK${nc}] "
                    else
                        local prompt="Confirmed /EFI System Partition"
                        ok
                    fi
                else
                    sleep 0.2
                    NC "

==> [EFI System Partition ${green}OK${nc}] "
                fi
            fi
        fi
    fi
#..................................................................................................
    if [[ "${fs}" == "1" ]]; then
        if [[ "${sep_home}" == "y" ]]; then
            if [[ -e "${home_dev}" ]]; then
                homeprt="ok"
                if [[ "${autohome}" == "y" ]]; then
                    if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                        sleep 0.2
                        NC "

==> [Linux /Home ${green}OK${nc}] "
                    else
                        local prompt="Confirmed /Home Partition"
                        ok
                    fi
                else
                    sleep 0.2
                    NC "

==> [Linux /Home ${green}OK${nc}] "
                fi
            else
                homeprt="fail"
                sleep 0.2
                RED "
        --------------------------------------------
        ###  ${yellowl}Linux /Home ${nc}Partition not detected  ${red}###
        --------------------------------------------"
            fi
        fi
    fi
#..................................................................................................
    if [[ "${swapmode}" == "1" ]]; then
        if [[ -e "${swap_dev}" ]]; then
            swapprt="ok"
            if [[ "${autoswap}" == "y" ]]; then
                if [[ "${presetpart}" == "y" || "${smartpart}" == "y" ]]; then
                    sleep 0.2
                    NC "

==> [Linux /Swap ${green}OK${nc}] "
                else
                    local prompt="Confirmed /Swap Partition"
                    ok
                fi
            else
                sleep 0.2
                NC "

==> [Linux /Swap ${green}OK${nc}] "
            fi
        else
            swapprt="fail"
            sleep 0.2
            RED "
        --------------------------------------------
        ###  ${yellowl}Linux /Swap ${nc}Partition not detected  ${red}###
        --------------------------------------------"
        fi
    fi
#..................................................................................................
    if [[ "${rootprt}" == "fail" || "${espprt}" == "fail" || "${xbootprt}" == "fail" || "${homeprt}" == "fail" || "${swapprt}" == "fail" ]]; then
        sanity="no"
    else
        sanity="ok"
    fi
#--------------------------------------------------------------------------------------------------    
    if [[ "${sanity}" == "ok" ]]; then
        if [[ "${smartpart}" == "y" ]]; then
            sleep 0.2
            NC "

==> [${green}Disk ${sgdrive} Smart-Partitioned OK${nc}] "
        elif [[ "${presetpart}" == "y" ]]; then
            sleep 0.2
            NC "

==> [${green}Disk ${sgdrive} Preset-Partitioned OK${nc}] "
        fi
        sleep 0.2
        NC "

        -----------------------
        ### ${green}SANITY CHECK OK${nc} ###
        -----------------------"
        sleep 0.2
        CYAN "


###${nc}------------------------------------------------${cyan}[ ${bwhite}DISK OVERVIEW ${nc}${cyan}]${nc}------------------------------------------------${cyan}###

        "
        fdisk -l "${instl_drive}" | grep -E --color=no 'Dev|dev' |GREP_COLORS='mt=01;36' grep -E --color=always 'EFI System|$'|GREP_COLORS='mt=01;32' grep -E --color=always 'Linux root|$'|GREP_COLORS='mt=01;35' grep -E --color=always 'Linux home|$'|GREP_COLORS='mt=01;33' grep -E --color=always 'Linux swap|$'|GREP_COLORS='mt=01;31' grep -E --color=always 'Linux extended boot|$'
        CYAN "

###${nc}-----------------------------------------------------------------------------------------------------------------${cyan}### "
        BLUE "


        >  Proceed using the ${nc}${cyan}current ${blue}partitioning layout ? [Y/n]
        "
        read -r -p "
==> " partok

        echo
        partok="${partok:-y}"
        partok="${partok,,}"

        local prompt="Disk Partitioning"
        local stage_prompt="Partitioning"

        if [[ "${partok}" == "y" ]]; then
            ok
            return 0
        elif [[ "${partok}" == "n" ]]; then
            if [[ "${multibooting}" == "n" ]]; then
                reload
                until auto_part; do : ; done
                return 0
            elif [[ "${multibooting}" == "y" ]]; then
                reload
                until manual_part; do : ; done
                return 0
            fi
        else
            y_n
            return 1
        fi
#--------------------------------------------------------------------------------------------------
    elif [[ "${sanity}" == "no" ]]; then
        sleep 0.2
        NC "

        -----------------------------
        ###  ${red}SANITY CHECK FAILED  ${nc}###
        -----------------------------"
        NC "



                                      ${bwhite}Press any key to continue${nc}


        "
        read -r -s -n 1
        
        if [[ "${multibooting}" == "y" ]]; then
            if [[ "${espprt}" == "fail" && -e "${esp_dev}" ]]; then
                sleep 0.2
                CYAN "
        --------------------------------------------------
        ###  ${yellowl}ESP: ${nc}Not all prerequisites are satisfied  ${cyan}###
        --------------------------------------------------"
                if [[ "${espmnt}" == "2" ]]; then
                    sleep 0.2
                    CYAN "

        >>  ${nc}Select ${yellowl}/mnt/efi ${nc}as the mountpoint for your ${yellowl}ESP "
                fi
                if [[ "${xbootprt}" == "fail" ]]; then
                    sleep 0.2
                    CYAN "

        >>  ${yellowl}Systemd-boot:${nc}${cyan}

        >>  ${nc}Create a ${yellowl}300M ${nc}(at minimum) Linux Extended Boot Partition ${bwhite}(XBOOTLDR) ${yellowl}[GUID CODE: ea00]
                "
                fi
                NC "


                                      ${bwhite}Press any key to continue${nc}
                "
                read -r -s -n 1

                if [[ "${espmnt}" == "2" ]]; then
                    until slct_espmnt; do : ; done
                fi
                if [[ "${xbootprt}" == "fail" ]]; then
                    until manual_part; do : ; done
                fi
            elif [[ "${espprt}" == "fail" && ! -e "${esp_dev}" ]]; then
                reload
                until manual_part; do : ; done
            elif [[ "${homeprt}" == "fail" || "${swapprt}" == "fail" ]]; then
                reload
                until manual_part; do : ; done
            fi
        elif [[ "${multibooting}" == "n" ]]; then
            reload
            until auto_part; do : ; done
        fi
    fi
}
