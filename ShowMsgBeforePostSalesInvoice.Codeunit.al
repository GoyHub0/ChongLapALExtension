namespace DefaultPublisher.ALProject3;

using Microsoft.Sales.Posting;
using Microsoft.Sales.Document;
using System.Utilities;

codeunit 50104 ShowMsgBeforePostSalesInvoice
{
    // trigger OnRun()
    // begin

    // end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesOrder(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean; var IsHandled: Boolean; var CalledBy: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmText: Text;
    begin

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;
        if PreviewMode then
            exit;

        SalesHeader.CalcFields("Amount Including VAT");
        if SalesHeader."Amount Including VAT" >= 500 then
            exit;

        if SalesHeader."Currency Code" <> 'HKD' then
            exit;

        // Show confirmation dialog
        ConfirmText := StrSubstNo(
            'The total amount is %1 %2, which is below the threshold of 500 HKD.\Do you want to continue posting?',
            SalesHeader."Amount Including VAT",
            SalesHeader."Currency Code"
        );

        if not ConfirmManagement.GetResponseOrDefault(ConfirmText, true) then
            Error('Posting cancelled by user.');
    end;

    var
        myInt: Integer;
}