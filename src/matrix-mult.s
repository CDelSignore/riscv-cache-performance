# =======================================================================
# DATA LAYER (DO NOT CHANGE)
# =======================================================================
.data
A:        .word   0
B:        .word   0
C:        .word   0
mismatch: .string "Incompatible dimensions for matrix multiplication"
fail_brk: .string "Failed to allocate memory"
A_label:  .string "Matrix A:\n"
B_label:  .string "Matrix B:\n"
C_label:  .string "Matrix C:\n"

# =======================================================================
# CHANGE DIMENSIONS HERE
# =======================================================================
.text
.equ A_ROWS, 6
.equ A_COLS, 5
.equ B_ROWS, 5
.equ B_COLS, 6

# =======================================================================
# RISC-V ASM PROGRAM TO CALCULATE MATRIX MULT C=A.B
# =======================================================================
MAIN:
    jal  CHECK_COMPAT               # Make sure provided dimensions are valid for operation

    la   a0, A                      # INIT_MATRIX(&A, A_ROWS, A_COLS, mode=counting)
    li   a1, A_ROWS
    li   a2, A_COLS
    li   a3, 1
    jal  INIT_MATRIX

    la   a0, B                      # INIT_MATRIX(&B, B_ROWS, B_COLS, mode=counting)
    li   a1, B_ROWS
    li   a2, B_COLS
    li   a3, 1
    jal  INIT_MATRIX

    la   a0, C                      # INIT_MATRIX(&C, A_ROWS, B_COLS, mode=zeros)
    li   a1, A_ROWS
    li   a2, B_COLS
    li   a3, 0
    jal  INIT_MATRIX

    la   a0, A                      # PRINT_MATRIX(&A, A.rows, A.cols, A.label)
    li   a1, A_ROWS
    li   a2, A_COLS
    la   a3, A_label
    jal  PRINT_MATRIX

    la   a0, B                      # PRINT_MATRIX(&B, B.rows, B.cols, B.label)
    li   a1, B_ROWS
    li   a2, B_COLS
    la   a3, B_label
    jal  PRINT_MATRIX

    jal  MATRIX_MULT                # Calculate C=A.B

    la   a0, C                      # PRINT_MATRIX(&C, C.rows, C.cols, C.label)
    li   a1, A_ROWS
    li   a2, B_COLS
    la   a3, C_label
    jal  PRINT_MATRIX

    call EXIT                       # Exit program

# =======================================================================
# Prints error message and terminates if A_COLS != B_ROWS
# =======================================================================
CHECK_COMPAT:
    li    t1, A_COLS
    li    t2, B_ROWS
    bne   t1, t2, ERR_MISMATCH      # If A.cols != B.rows Then Throw Error
    ret

ERR_MISMATCH:
    la    a0, mismatch              # Print error message
    li    a7, 4
    ecall

    li    a0, 1                     # Exit with code (1)
    li    a7, 93
    ecall

# =======================================================================
# Initializes a maxtrix with incrementing numbers
#     -> a0: address to store pointer to data
#     -> a1: number of rows in matrix
#     -> a2: number of cols in matrix
#     -> a3: boolean, init matrix with zeros if false
# =======================================================================
INIT_MATRIX:
    mul   t1, a1, a2                # len(M) = M_ROWS * M_COLS
    slli  t1, t1, 2                 # size(A) = len(A) * 4
    sub   t1, x0, t1                # -size(A)
    mv    t2, sp                    # save old stack pointer
    add   sp, sp, t1                # allocate space on the stack
    sw    sp, 0(a0)                 # store location of M data on stack

    mv    t1, sp                    # &M[i]
    li    t3, 0                     # i = 0
    
LOOPA:
    bge   t1, t2, EXITA             # For each [word] in M:
    beq   a3, x0, NEXTA             # keep i at 0 if a0=0
    addi  t3, t3, 1                 # i++
NEXTA:
    sw    t3, 0(t1)                 # M[word] = i
    addi  t1, t1, 4                 # next M[word]
    j     LOOPA                     # LOOP

EXITA:
    ret                             # RETURN

# =======================================================================
# Prints a matrix to the console
#     -> a0: pointer address for matrix
#     -> a1: number of rows in matrix
#     -> a2: number of cols in matrix
#     -> a3: label to display
# =======================================================================
PRINT_MATRIX:
    lw    t1, 0(a0)                 # &M
    li    t2, 0                     # int i=0
    mul   t4, a1, a2                # rows*cols

    mv    t3, a0                    # Print the label (eg "Matrix M:")
    mv    a0, a3
    li    a7, 4
    ecall
    mv    a0, t3

LOOPB:
    bge   t2, t4, EXITB             # for(int i=0; i<M.rows*M.cols; i++)

    lw    a0, 0(t1)                 # print M[i]
    li    a7, 1
    ecall

    li    a0, 0x09                  # print TAB char
    li    a7, 11
    ecall

    sub   t3, t2, a2                # If at end of column, print newline
    addi  t3, t3, 1
    rem   t3, t3, a2
    bne   t3, x0, NEXTB
    beq   t2, x0, NEXTB
    li    a0, 0x0A
    li    a7, 11
    ecall    

NEXTB:
    addi  t2, t2, 1                 # i++
    addi  t1, t1, 4                 # next word in M
    j     LOOPB                     # LOOP

EXITB:
    li    a0, 0x0A                  # print newline char
    li    a7, 11
    ecall    

    ret                             # RETURN

# =======================================================================
# Performs a matrix multiplication C=A.B
# =======================================================================
MATRIX_MULT:
    la   s1, A
    la   s2, B
    la   s3, C
    lw   s1, 0(s1)                  # s1 = &A
    lw   s2, 0(s2)                  # s2 = &B
    lw   s3, 0(s3)                  # s3 = &C

    li   s4, A_ROWS                 # s4 = A.rows
    li   s5, B_ROWS                 # s5 = B.rows
    li   s6, B_COLS                 # s6 = B.cols
    li   s7, A_COLS                 # s7 = B.cols

    li   t4, 0                      # int i=0
LOOPC:
    bge  t4, s4, EXITC              # for(int i=0; i<A.rows; i++)
    li   t6, 0                      # int j=0

LOOPD:
    bge  t6, s6, EXITD              # for(int j=0; j<B.cols; j++)
    li   t5, 0                      # int k=0
    li   s8, 0                      # int result = 0

LOOPE:
    bge  t5, s5, EXITE              # for(int k=0; k<B.rows; k++)

    mul  t2, t4, s7                 # A[i][k] = A[4(i*A.cols+k)]
    add  t2, t2, t5
    slli t2, t2, 2
    add  t2, t2, s1
    lw   t2, 0(t2)

    mul  t3, t5, s6                 # B[k][j] = B[4(k*B.cols+j)]
    add  t3, t3, t6
    slli t3, t3, 2
    add  t3, t3, s2
    lw   t3, 0(t3)

    mul  t1, t2, t3                 # result += A[i][k] * B[k][j]
    add  s8, s8, t1

    addi t5, t5, 1                  # k++
    j    LOOPE                      # LOOP

EXITE:
    sw   s8, 0(s3)                  # C[n] = result

    addi s3, s3, 4                  # next word in C
    addi t6, t6, 1                  # j++
    j    LOOPD                      # LOOP

EXITD:
    addi t4, t4, 1                  # i++
    j    LOOPC                      # LOOP

EXITC:
    ret                             # RETURN

# =======================================================================
# Exits program normally
# =======================================================================
EXIT:
    li   a7, 10
    ecall