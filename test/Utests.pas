unit Utests;

interface

uses
    Dunitx.TestFramework;

type

    [TestFixture]
    TlogTest = class
        // [Test]
        // [TestCase('Case 0: interactiveButtonReply', '../../files/interactiveButtonReply.json,Teste,8151fb8e-bb51-443c-a2a6-23c73c56a7da')]
        // procedure test(testFile: string; expectedTitle: string; expectedId: string);
    end;

implementation

uses
    System.Classes,
    System.SysUtils,
    System.IOUtils,
    Ulog;

initialization
    TDUnitX.RegisterTestFixture(TlogTest);
end.
