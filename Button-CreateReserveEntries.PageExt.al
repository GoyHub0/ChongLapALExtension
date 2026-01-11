namespace ALProject3;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Tracking;
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
        }
    }

    local procedure DeleteReserveEntries()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", Rec."No.");
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
        ReservMgmt.DeleteDocumentReservation(
            Database::"Sales Line",
            SalesLine."Document Type".AsInteger(),
            SalesLine."Document No.",
            false
        );
    end;
}