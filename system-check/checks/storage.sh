#!/bin/bash

run_storage_check() {
    echo ""
    echo -e "${GREEN}=== Armazenamento ===${NC}"
    echo ""

    local partitions
    partitions=$(df -h --output=target,pcent,used,size,fstype 2>/dev/null \
        | awk 'NR>1 && ($5=="ext4" || $5=="xfs" || $5=="btrfs" || $5=="vfat") {print}')

    if [ -z "$partitions" ]; then
        log_warning "Nenhuma partição relevante encontrada."
        save_result "Disco" "WARN" "nenhuma partição detectada"
    else
        while IFS= read -r line; do
            local mountpoint pct_str pct used size
            mountpoint=$(echo "$line" | awk '{print $1}')
            pct_str=$(echo "$line"    | awk '{print $2}')
            pct="${pct_str//%/}"
            used=$(echo "$line"       | awk '{print $3}')
            size=$(echo "$line"       | awk '{print $4}')

            if [ "$pct" -ge 95 ]; then
                save_result "Disco $mountpoint" "FAIL" "${pct}% usado (${used}/${size})"
                log_error "Disco $mountpoint — ${pct}% usado"
            elif [ "$pct" -ge 85 ]; then
                save_result "Disco $mountpoint" "WARN" "${pct}% usado (${used}/${size})"
                log_warning "Disco $mountpoint — ${pct}% usado"
            else
                save_result "Disco $mountpoint" "OK" "${pct}% usado (${used}/${size})"
                log_info "Disco $mountpoint — ${pct}% usado (${used}/${size})"
            fi
        done <<< "$partitions"
    fi

    local inode_partitions
    inode_partitions=$(df -i --output=target,ipcent,fstype 2>/dev/null \
        | awk 'NR>1 && ($3=="ext4" || $3=="xfs" || $3=="btrfs") && $2!="-" {print}')

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local mountpoint ipcent_str ipcent
        mountpoint=$(echo "$line"  | awk '{print $1}')
        ipcent_str=$(echo "$line"  | awk '{print $2}')
        ipcent="${ipcent_str//%/}"

        if [ "$ipcent" -ge 85 ]; then
            save_result "Inodes $mountpoint" "WARN" "${ipcent}% usado"
            log_warning "Inodes $mountpoint — ${ipcent}% usado"
        else
            save_result "Inodes $mountpoint" "OK" "${ipcent}% usado"
            log_info "Inodes $mountpoint — ${ipcent}% usado"
        fi
    done <<< "$inode_partitions"

    echo ""
    echo "Top 5 maiores diretórios em /:"
    du -sh --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run \
        /*/  2>/dev/null \
        | sort -rh | head -5 \
        | while read -r sz dir; do printf "  %-8s %s\n" "$sz" "$dir"; done
    echo ""

    {
        echo "--- Armazenamento (df -h) ---"
        df -h 2>/dev/null
        echo ""
    } >> "$REPORT_FILE"
}
