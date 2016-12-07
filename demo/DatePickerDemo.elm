module DatePickerDemo exposing (main)

import Html exposing (Html, text, p, label, form, ul, li)
import Html.Attributes as Html exposing (style, for)
import DatePicker
import Date exposing (Date)
import Css
import DatePicker.Css
import Date.Extra.Format
import Date.Extra.Config.Config_en_us exposing (config)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { value : Maybe Date
    , datePickerState : DatePicker.State
    , secondValue : Maybe Date
    , secondDatePickerState : DatePicker.State
    }


init : ( Model, Cmd Msg )
init =
    ( { value = Nothing, datePickerState = DatePicker.initialState, secondValue = Nothing, secondDatePickerState = DatePicker.initialState }
    , Cmd.batch
        [ DatePicker.initialCmd DatePickerStateChanged DatePicker.initialState
        , DatePicker.initialCmd SecondDatePickerStateChanged DatePicker.initialState
        ]
    )


datePickerOptions : DatePicker.Options Msg
datePickerOptions =
    let
        defaultOptions =
            DatePicker.defaultOptions DateChanged DatePickerStateChanged

        nameOfDays =
            defaultOptions.nameOfDays
    in
        defaultOptions


secondDatePickerOptions : DatePicker.Options Msg
secondDatePickerOptions =
    let
        defaultOptions =
            DatePicker.defaultOptions SecondDateChanged SecondDatePickerStateChanged

        nameOfDays =
            defaultOptions.nameOfDays
    in
        defaultOptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    let
        { css } =
            Css.compile [ DatePicker.Css.css ]
    in
        form []
            [ Html.node "style" [] [ Html.text css ]
            , p
                []
                [ label []
                    [ text "Date Picker #1: "
                    , DatePicker.datePicker
                        datePickerOptions
                        []
                        model.datePickerState
                        model.value
                    ]
                ]
            , p
                []
                [ label []
                    [ text "Date Picker #2 : "
                    , DatePicker.datePicker
                        secondDatePickerOptions
                        []
                        model.secondDatePickerState
                        model.secondValue
                    ]
                ]
            , p []
                [ ul []
                    [ li [] [ text "Value: ", text <| toString model.value ]
                    , li [] [ text "Second Value: ", text <| toString model.secondValue ]
                    ]
                ]
            ]


type Msg
    = NoOp
    | DateChanged (Maybe Date)
    | DatePickerStateChanged DatePicker.State
    | SecondDateChanged (Maybe Date)
    | SecondDatePickerStateChanged DatePicker.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        DateChanged value ->
            ( { model | value = value }, Cmd.none )

        DatePickerStateChanged state ->
            ( { model | datePickerState = state }, Cmd.none )

        SecondDateChanged value ->
            ( { model | secondValue = value }, Cmd.none )

        SecondDatePickerStateChanged state ->
            ( { model | secondDatePickerState = state }, Cmd.none )
