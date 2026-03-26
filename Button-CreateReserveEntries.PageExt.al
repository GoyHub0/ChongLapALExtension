namespace ALProject3;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Foundation.Company;
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
                var
                    Helper: Codeunit ReserveEntriesHelper;
                begin
                    Message('Button Delete Reserve Entries clicked.');
                    Helper.DeleteReserveEntries(Rec);
                end;
            }
            action(CreateReserveEntries)
            {
                ApplicationArea = All;
                Caption = 'Assign Lot Nos.';
                trigger OnAction()
                var
                    Helper: Codeunit ReserveEntriesHelper;
                begin
                    Message('Button Assign Lot Nos. clicked.');
                    Helper.CreateReserveEntries(Rec);
                end;
            }
        }
    }
}