module CIPU(
    input clk,
    input rst,
    input [7:0] people_thing_in,
    input ready_fifo,
    input ready_lifo,
    input [7:0] thing_in,
    input [3:0] thing_num,
    output reg valid_fifo,
    output reg valid_lifo,
    output reg valid_fifo2,
    output reg [7:0] people_thing_out,
    output reg [7:0] thing_out,
    output reg done_thing,
    output reg done_fifo,
    output reg done_lifo,
    output reg done_fifo2
);

    parameter state_A = 2'b00;
    parameter state_B = 2'b01;
    parameter state_C = 2'b10;
    parameter state_D = 2'b11;

    // FIFO
    // -----
    reg [1:0] fifo_state = state_A;
    reg [1:0] fifo_old_state;

    reg ready_fifo_trigger = 0;

    reg [15:0] fifo_list_pointer = 0;
    reg [15:0] fifo_list_counter = 0;
    reg [7:0] fifo_list [15:0];
    // -----

    always @(posedge clk)
    begin
        fifo_old_state = fifo_state;

        if (fifo_state == state_A)
        begin
            if (ready_fifo)
            begin
                ready_fifo_trigger = 1;
            end
            else if (!ready_fifo && ready_fifo_trigger == 1)
            begin
                ready_fifo_trigger = 0;
                fifo_state = state_B;
                fifo_old_state = fifo_state;
            end
            else if (done_fifo)
            begin
                done_fifo = 0;
            end
            else
            begin
                fifo_state = fifo_old_state;
            end
        end
        else
        begin
            fifo_state = fifo_old_state;
        end

        if(fifo_state == state_B)
        begin
            if(people_thing_in >= "A" && people_thing_in <= "Z")
            begin
                fifo_list[fifo_list_counter] = people_thing_in;
                fifo_list_counter = fifo_list_counter + 1;
            end
            else if(people_thing_in == "$")
            begin
                valid_fifo = 1;
                fifo_state = state_D;
                fifo_old_state = fifo_state;
            end
            else
            begin
                fifo_state = fifo_old_state;
            end
        end
        else
        begin
            fifo_state = fifo_old_state;
        end

        if(fifo_state == state_D)
        begin
            people_thing_out = fifo_list[fifo_list_pointer];
            fifo_list_pointer = fifo_list_pointer + 1;

            if(fifo_list_pointer > fifo_list_counter)
            begin
                valid_fifo = 0;
                done_fifo = 1;

                fifo_state = state_A;
                fifo_old_state = fifo_state;
            end
            else
            begin
                valid_fifo = 1;
                done_fifo = 0;
            end
        end
        else
        begin
            fifo_state = fifo_old_state;
        end
    end

    // LIFO & FIFO2
    // -----
    reg [1:0] lifo_state = state_A;
    reg [1:0] lifo_old_state;

    reg ready_lifo_trigger = 0;

    reg [15:0] lifo_list_pointer = 0;
    reg [15:0] lifo_list_counter = 0;
    reg [7:0] lifo_list [128:0];

    reg [15:0] _one_data_list_pointer = 0;
    reg [15:0] one_data_list_pointer = 0;
    reg [15:0] one_data_list_counter = 0;
    reg [7:0] one_data_list [15:0];

    reg [15:0] fifo2_list_pointer = 0;
    reg [15:0] fifo2_list_counter = 0;
    reg [7:0] fifo2_list [15:0];

    reg [1:0] sth_in_lifo_list = 0;
    reg [1:0] sth_in_fifo2_list = 0;
    // -----

    always @(posedge clk)
    begin
        lifo_old_state = lifo_state;

        if (lifo_state == state_A)
        begin
            if (ready_lifo)
            begin
                ready_lifo_trigger = 1;
            end
            else if (!ready_lifo && ready_lifo_trigger == 1)
            begin
                ready_lifo_trigger = 0;
                lifo_state = state_B;
                lifo_old_state = lifo_state;
            end
            else if (done_lifo)
            begin
                done_lifo = 0;
            end
            else
            begin
                done_lifo = 0;

                lifo_state = lifo_old_state;
            end
        end
        else
        begin
            lifo_state = lifo_old_state;
        end

        if(lifo_state == state_B)
        begin
            if (done_thing)
            begin
                done_thing = 0;
            end
            else
            begin
                if (thing_in >= "1" && thing_in <= "9")
                begin
                    one_data_list[one_data_list_counter] = thing_in;
                    one_data_list_counter = one_data_list_counter + 1;
                end
                else if(thing_in == ";")
                begin
                    _one_data_list_pointer = 0;
                    one_data_list_pointer = one_data_list_counter;

                    lifo_list_pointer = lifo_list_counter;
                    fifo2_list_pointer = fifo2_list_counter;

                    sth_in_lifo_list = 0;
                    sth_in_fifo2_list = 0;

                    lifo_state = state_C;
                    lifo_old_state = lifo_state;
                end
                else if(people_thing_in == "$")
                begin
                    lifo_state = state_D;
                    lifo_old_state = lifo_state;
                end
                else
                begin
                    lifo_state = lifo_old_state;
                end
            end
        end
        else
        begin
            lifo_state = lifo_old_state;
        end

        if(lifo_state == state_C)
        begin
            // No baggage situation.
            if (one_data_list_counter == 0)
            begin
                lifo_list[lifo_list_counter] = "0";

                lifo_list_counter = lifo_list_counter + 1;

                one_data_list_pointer = one_data_list_pointer - 1;
                one_data_list_counter = one_data_list_counter - 1;
            end
            // The pointer is overflowed (< 0).
            else if (one_data_list_pointer >= 16)
            begin
                if (sth_in_lifo_list == 0 && sth_in_fifo2_list == 1 && thing_num == 0)
                begin
                    lifo_list[lifo_list_counter] = "0";

                    lifo_list_counter = lifo_list_counter + 1;
                    sth_in_lifo_list = 1;
                end
                else
                begin
                    if (lifo_list_pointer < lifo_list_counter)
                    begin
                        valid_lifo = 1;

                        thing_out = lifo_list[lifo_list_pointer];
                        lifo_list_pointer = lifo_list_pointer + 1;
                    end
                    else
                    begin
                        if (valid_lifo)
                        begin
                            valid_lifo = 0;
                        end
                        else
                        begin
                            done_thing = 1;

                            one_data_list_pointer = 0;
                            one_data_list_counter = 0;

                            lifo_state = state_B;
                            lifo_old_state = lifo_state;
                        end
                    end
                end
            end
            else
            begin
                if (one_data_list_pointer > one_data_list_counter - thing_num)
                begin
                    lifo_list[lifo_list_counter] = one_data_list[one_data_list_pointer - 1];

                    lifo_list_counter = lifo_list_counter + 1;
                    one_data_list_pointer = one_data_list_pointer - 1;

                    if (sth_in_lifo_list == 0)
                    begin
                        sth_in_lifo_list = 1;
                    end
                end
                else
                begin
                    if (_one_data_list_pointer < one_data_list_pointer)
                    begin
                        fifo2_list[fifo2_list_counter] = one_data_list[_one_data_list_pointer];

                        fifo2_list_counter = fifo2_list_counter + 1;
                        _one_data_list_pointer = _one_data_list_pointer + 1;
                    end
                    else
                    begin
                        one_data_list_pointer = -1;
                    end

                    if (sth_in_fifo2_list == 0)
                    begin
                        sth_in_fifo2_list = 1;
                    end
                end
            end
        end
        else
        begin
            lifo_state = lifo_old_state;
        end

        if(lifo_state == state_D)
        begin
            done_lifo = 1;
            lifo_state = state_A;
            lifo_old_state = lifo_state;
        end
        else
        begin
            lifo_state = lifo_old_state;
        end
    end

    // FIFO2
    // -----
    reg [1:0] fifo2_state = state_A;
    reg [1:0] fifo2_old_state;

    reg ready_fifo2_trigger = 0;
    // -----

    always @(posedge clk)
    begin
        fifo2_old_state = fifo2_state;

        if (fifo2_state == state_A)
        begin
            if (done_lifo)
            begin
                ready_fifo2_trigger = 1;
            end
            else if (!done_lifo && ready_fifo2_trigger == 1)
            begin
                ready_fifo2_trigger = 0;

                fifo2_list_pointer = 0;

                valid_fifo2 = 0;

                fifo2_state = state_B;
                fifo2_old_state = fifo2_state;
            end
            else
            begin
                done_fifo2 = 0;

                fifo2_state = fifo2_old_state;
            end
        end
        else
        begin
            fifo2_state = fifo2_old_state;
        end

        if (fifo2_state == state_B)
        begin
            if (fifo2_list_pointer < fifo2_list_counter)
            begin
                if (valid_fifo2 == 0)
                begin
                    valid_fifo2 = 1;

                    thing_out = fifo2_list[fifo2_list_pointer];
                    fifo2_list_pointer = fifo2_list_pointer + 1;
                end
                else
                begin
                    valid_fifo2 = 0;
                end
            end
            else
            begin
                if (valid_fifo2)
                begin
                    valid_fifo2 = 0;
                end
                else
                begin
                    done_fifo2 = 1;

                    fifo2_state = state_A;
                    fifo2_old_state = fifo2_state;
                end
            end
        end
    end
endmodule
