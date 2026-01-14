#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

int main(int argc, char *argv[]) {
    FILE *fin = stdin;
    if (argc > 1) {
        fin = fopen(argv[1], "r");
    }

    int max1 = -1;
    int max2 = -1;
    int saved_max1;
    int saved_max2;
    int saved_ch;
    int ch;
    int max1_just_found = false;
    int result = 0;

    while ((ch = getc(fin)) != EOF) {
        if (ch == '\n') {
            if (max1_just_found) {
                max1 = saved_max1;
                max2 = saved_max2;
                if (saved_ch > max2) {
                    max2 = saved_ch;
                }
            }
            int partial_result = (int)(max1 - '0') * 10 + (int)(max2 - '0');
            result += partial_result;
            max1 = -1;
            max2 = -1;
        }
        max1_just_found = false;
        if (ch > max1) {
            saved_max1 = max1;
            saved_max2 = max2;
            saved_ch = ch;
            max1 = ch;
            max2 = -1;
            max1_just_found = true;
        } else if (ch > max2) {
            max2 = ch;
        }
    }

    printf("%d\n", result);

    // Not needed at all, but I feel dirty if I don't close the file
    if (argc > 1) {
        fclose(fin);
    }
    return EXIT_SUCCESS;
}
