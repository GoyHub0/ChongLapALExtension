namespace ALProject3;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
pageextension 50110 ButtonCreateReserveEntries extends "Sales Order Subform"
{
    actions
    {
        // Add changes to page actions here
        addlast(processing)
        {
            action(DeleteReserveEntries)
            {
                ApplicationArea = All;
                Caption = 'Delete Reserve Entries';
                trigger OnAction()
                begin
                    Message('Button Delete Reserve Entries clicked.');
                    DeleteReserveEntries();
                end;
            }
            action(CreateReserveEntries)
            {
                ApplicationArea = All;
                Caption = 'Assign Lot Nos.';
                trigger OnAction()
                begin
                    Message('Button Assign Lot Nos. clicked.');
                    CreateReserveEntries();
                end;
            }
        }
    }

    local procedure DeleteReserveEntries()
    var
        SalesLine: Record "Sales Line";
    begin
        // SalesLine.SetRecFilter();
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."Document No.");
        if SalesLine.FindSet() then begin
            repeat
                DeleteReservationEntriesForLine(SalesLine);
            until SalesLine.Next() = 0;
        end;
    end;

    local procedure DeleteReservationEntriesForLine(var SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ReservMgmt: Codeunit "Reservation Management";
    begin
        ReservationEntry.SetSourceFilter(
            Database::"Sales Line",
            SalesLine."Document Type".AsInteger(),
            SalesLine."Document No.",
            SalesLine."Line No.",
            true
        );
        if ReservationEntry.FindSet() then begin
            repeat
                ReservationEntry.Delete();
            until ReservationEntry.Next() = 0;
        end;
        // ReservMgmt.DeleteDocumentReservation(
        //     Database::"Sales Line",
        //     SalesLine."Document Type".AsInteger(),
        //     SalesLine."Docum ent No.",
        //     false
        // );
        // ReservMgmt.SetReservSource(SalesLine);
        // ReservMgmt.DeleteReservEntries(true, 0);
    end;

    local procedure CreateReserveEntries()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."Document No.");
        if SalesLine.FindSet() then begin
            repeat
                CreateReservationEntriesForLine(SalesLine);
            until SalesLine.Next() = 0;
        end;
    end;

    local procedure CreateReservationEntriesForLine(var SalesLine: Record "Sales Line")
    var
        ReservMgmt: Codeunit "Reservation Management";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        QtyLeftToReserve: Decimal;
        NextReservationEntryNo: Integer;
        QtyInCurrentLedgerEntry: Decimal;
    begin

        if SalesLine."No." = '' then
            exit;

        if not Item.Get(SalesLine."No.") then
            exit;

        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit;

        if not ItemTrackingCode."Lot Specific Tracking" then
            exit;

        QtyLeftToReserve := SalesLine."Quantity (Base)";

        ItemLedgerEntry.SetCurrentKey("Item No.", "Lot No.");
        ItemLedgerEntry.SetRange("Item No.", SalesLine."No.");
        ItemLedgerEntry.SetAscending("Lot No.", true);


        if ReservationEntry.FindLast() then
            NextReservationEntryNo := ReservationEntry."Entry No."
        else
            NextReservationEntryNo := 1;

        // Delete existing reservations for this sales line
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservationEntry.DeleteAll();

        if ItemLedgerEntry.FindSet() then begin
            repeat
                // QtyInCurrentLot := 0;
                // // Accumulate quantity in the same lot in QtyInCurrentLot
                // repeat
                //     QtyInCurrentLot += ItemLedgerEntry."Remaining Quantity";
                //     if QtyInCurrentLot > QtyLeftToReserve then
                //         break;
                //     TempItemLedgerEntry := ItemLedgerEntry;
                //     if (TempItemLedgerEntry.Next() = 0) or (TempItemLedgerEntry."Lot No." <> ItemLedgerEntry."Lot No.") then
                //         break;
                //     ItemLedgerEntry := TempItemLedgerEntry;
                // until false;

                // Create Reservation Entry for the lot
                ReservationEntry.Reset();
                NextReservationEntryNo += 1;
                ReservationEntry.Init();
                ReservationEntry."Entry No." := NextReservationEntryNo;
                ReservationEntry."Item No." := SalesLine."No.";
                ReservationEntry."Lot No." := ItemLedgerEntry."Lot No.";

                // Mandatory fields
                ReservationEntry."Location Code" := SalesLine."Location Code";
                ReservationEntry."Variant Code" := SalesLine."Variant Code";

                QtyInCurrentLedgerEntry := ItemLedgerEntry."Remaining Quantity";
                if QtyLeftToReserve <= QtyInCurrentLedgerEntry then begin
                    ReservationEntry."Quantity (Base)" := -QtyLeftToReserve;
                    ReservationEntry."Qty. to Handle (Base)" := -QtyLeftToReserve;
                    ReservationEntry."Qty. to Invoice (Base)" := -QtyLeftToReserve;
                    QtyLeftToReserve := 0
                end else begin
                    ReservationEntry."Quantity (Base)" := -QtyInCurrentLedgerEntry;
                    ReservationEntry."Qty. to Handle (Base)" := -QtyInCurrentLedgerEntry;
                    ReservationEntry."Qty. to Invoice (Base)" := -QtyInCurrentLedgerEntry;
                    QtyLeftToReserve -= QtyInCurrentLedgerEntry;
                end;

                ReservationEntry."Source Type" := Database::"Sales Line";
                ReservationEntry."Source Subtype" := SalesLine."Document Type".AsInteger();
                ReservationEntry."Source ID" := SalesLine."Document No.";
                ReservationEntry."Source Ref. No." := SalesLine."Line No.";
                ReservationEntry.Positive := false;
                ReservationEntry.Insert();

                ReservationEntry."Source Type" := Database::"Item Ledger Entry";
                ReservationEntry."Source Subtype" := ItemLedgerEntry."Document Type".AsInteger();
                ReservationEntry."Source ID" := ItemLedgerEntry."Document No.";
                ReservationEntry."Source Ref. No." := ItemLedgerEntry."Entry No.";
                ReservationEntry.Positive := true;
                ReservationEntry.Insert();

            until (QtyLeftToReserve <= 0) or (ItemLedgerEntry.Next() = 0);
        end;
    end;

}