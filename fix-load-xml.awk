/^<data/ { next; }
/^<\/data/ { next; }
/^<config/ { next; }
/^<\/config/ { next; }

/<!-- PPL -->/ {
    # pretty print leaf value
    split($0, a, "<|>");
    # a now contains ["", indent, tag, "", "!-- PPL --", val, /tag]
    printf("%s<%s>\n%s  %s\n%s</%s>\n", a[1], a[2], a[1], a[5], a[1], a[2]);
    next;
}

/<!-- ALT/ { next; }
/ALT -->/ { next; }
/SKIP-NEXT/ { skip_next=1; next; }
skip_next == 1 { skip_next = 0; next; }

{print $0; }
