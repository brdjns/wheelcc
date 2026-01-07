#include "definitionen.h"

Ganz Haupt(Ganz Argz, Zeichen** Argw) {
    setzenZ("Hallo Welt!");
    wenn (Argz == 2) {
        wenn (!Zkettevrgl(Argw[1], ZeichenKette(42))) {
            zuruck zweiundvierzig;
        }
    }
    zuruck Argz - 1;
}
